#!/usr/bin/env python3
"""Headless OpenSCAD geometry renderer + colored side-profile overlap (no GL).

Exports binary STL via OpenSCAD (no OpenGL needed) and draws it with
matplotlib's Agg backend. Self-bootstraps its Python deps on first run.
"""
import argparse
import os
import subprocess
import sys
import tempfile

_THIS = os.path.abspath(__file__)


def _ensure_deps():
    try:
        import numpy  # noqa: F401
        import stl  # noqa: F401  (numpy-stl)
        import matplotlib  # noqa: F401
        return
    except ImportError:
        if os.environ.get("_RENDER_STL_BOOTSTRAPPED"):
            raise
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", "--user",
            "--break-system-packages", "--quiet",
            "numpy", "numpy-stl", "matplotlib",
        ])
        os.environ["_RENDER_STL_BOOTSTRAPPED"] = "1"
        os.execv(sys.executable, [sys.executable, _THIS, *sys.argv[1:]])


_ensure_deps()

import numpy as np  # noqa: E402
from stl import mesh as stlmesh  # noqa: E402
import matplotlib  # noqa: E402
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.collections import PatchCollection  # noqa: E402
from matplotlib.patches import Polygon as MplPolygon  # noqa: E402
from mpl_toolkits.mplot3d.art3d import Poly3DCollection  # noqa: E402


def _find_openscadpath(scad_path):
    d = os.path.dirname(os.path.abspath(scad_path))
    while True:
        cand = os.path.join(d, "libraries")
        if os.path.isdir(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def _export_stl(scad_path, stl_path):
    if not os.path.isfile(scad_path):
        raise SystemExit("input not found: %s" % scad_path)
    env = dict(os.environ)
    libs = _find_openscadpath(scad_path)
    if libs:
        env["OPENSCADPATH"] = libs
    proc = subprocess.run(
        ["openscad", "--export-format", "binstl", "-o", stl_path, scad_path],
        capture_output=True, text=True, env=env,
    )
    if proc.returncode != 0 or not os.path.exists(stl_path) or os.path.getsize(stl_path) == 0:
        sys.stderr.write(proc.stderr or "")
        raise SystemExit("OpenSCAD export failed for %s" % scad_path)
    return stlmesh.Mesh.from_file(stl_path)


def _bounds(vectors):
    pts = vectors.reshape(-1, 3)
    return pts.min(axis=0), pts.max(axis=0)


def _set_axes_equal(ax, vectors):
    lo, hi = _bounds(vectors)
    ctr = (lo + hi) / 2.0
    r = float((hi - lo).max()) / 2.0 or 1.0
    ax.set_xlim(ctr[0] - r, ctr[0] + r)
    ax.set_ylim(ctr[1] - r, ctr[1] + r)
    ax.set_zlim(ctr[2] - r, ctr[2] + r)


_VIEW_ANGLES = {"iso": (30, -60), "top": (90, -90), "side": (0, 0)}


def render_single(scad_path, out_path, views):
    with tempfile.TemporaryDirectory() as td:
        m = _export_stl(scad_path, os.path.join(td, "p.stl"))
    fig = plt.figure(figsize=(5 * len(views), 5))
    for i, v in enumerate(views):
        ax = fig.add_subplot(1, len(views), i + 1, projection="3d")
        ax.add_collection3d(Poly3DCollection(
            m.vectors, facecolor="#d4a017", edgecolor="k", linewidths=0.1))
        _set_axes_equal(ax, m.vectors)
        elev, azim = _VIEW_ANGLES.get(v, (30, -60))
        ax.view_init(elev=elev, azim=azim)
        ax.set_title(v)
        ax.set_axis_off()
    fig.tight_layout()
    fig.savefig(out_path, dpi=100)
    plt.close(fig)


def render_overlay(scad_paths, out_path, axis):
    idx = {"yz": (1, 2), "xz": (0, 2)}[axis]
    colors = plt.cm.tab10.colors
    fig, ax = plt.subplots(figsize=(7, 7))
    allpts = []
    with tempfile.TemporaryDirectory() as td:
        for i, sp in enumerate(scad_paths):
            m = _export_stl(sp, os.path.join(td, "p%d.stl" % i))
            tris = m.vectors[:, :, idx]  # (n, 3, 2)
            allpts.append(tris.reshape(-1, 2))
            patches = [MplPolygon(tri, closed=True) for tri in tris]
            ax.add_collection(PatchCollection(
                patches, facecolor=colors[i % len(colors)],
                edgecolor="none", alpha=0.45))
            ax.plot([], [], color=colors[i % len(colors)],
                    label=os.path.basename(sp))
    pts = np.vstack(allpts)
    ax.set_xlim(pts[:, 0].min(), pts[:, 0].max())
    ax.set_ylim(pts[:, 1].min(), pts[:, 1].max())
    ax.set_aspect("equal")
    ax.set_xlabel(axis[0].upper())
    ax.set_ylabel(axis[1].upper())
    ax.set_title("overlap (%s)" % axis)
    ax.legend(loc="best", fontsize=8)
    fig.savefig(out_path, dpi=100)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(description="Headless OpenSCAD renderer + overlap view")
    ap.add_argument("files", nargs="+", help="one .scad (render) or 2+ (with --overlay)")
    ap.add_argument("--overlay", action="store_true", help="colored side-profile overlap of 2+ parts")
    ap.add_argument("--out", help="output PNG path")
    ap.add_argument("--views", default="iso,top,side", help="comma list: iso,top,side")
    ap.add_argument("--axis", default="yz", choices=["yz", "xz"], help="overlap projection plane")
    args = ap.parse_args()

    if args.overlay:
        if len(args.files) < 2:
            raise SystemExit("--overlay needs at least two .scad files")
        out = args.out or "overlay.png"
        render_overlay(args.files, out, args.axis)
    else:
        scad = args.files[0]
        out = args.out or (os.path.splitext(scad)[0] + ".png")
        render_single(scad, out, [v for v in args.views.split(",") if v])
    print(out)


if __name__ == "__main__":
    main()
