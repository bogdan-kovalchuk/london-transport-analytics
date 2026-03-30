from __future__ import annotations

import os
import pathlib
import subprocess

APP_URL = "http://127.0.0.1:8501"
OUTPUT_PATH = pathlib.Path("dashboard/assets/london_transport_dashboard.png")
LOCAL_LIB_ROOT = pathlib.Path(".local/browser-libs")
LOCAL_LIB_DIRS = [
    LOCAL_LIB_ROOT / "usr/lib/x86_64-linux-gnu",
    LOCAL_LIB_ROOT / "lib/x86_64-linux-gnu",
]
REQUIRED_PACKAGES = ["libnspr4", "libnss3", "libasound2t64"]


def ensure_browser_runtime_libraries() -> str:
    required_files = [
        LOCAL_LIB_DIRS[0] / "libnspr4.so",
        LOCAL_LIB_DIRS[0] / "libnss3.so",
        LOCAL_LIB_DIRS[0] / "libnssutil3.so",
        LOCAL_LIB_DIRS[0] / "libasound.so.2",
    ]

    if not all(path.exists() for path in required_files):
        deb_dir = LOCAL_LIB_ROOT / "debs"
        deb_dir.mkdir(parents=True, exist_ok=True)

        download_command = f"cd {deb_dir} && apt download {' '.join(REQUIRED_PACKAGES)}"
        subprocess.run(["bash", "-lc", download_command], check=True)

        for deb_file in deb_dir.glob("*.deb"):
            subprocess.run(["dpkg-deb", "-x", str(deb_file), str(LOCAL_LIB_ROOT)], check=True)

    return ":".join(str(path) for path in LOCAL_LIB_DIRS if path.exists())


def main() -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    library_path = ensure_browser_runtime_libraries()
    env = os.environ.copy()
    existing_library_path = env.get("LD_LIBRARY_PATH", "")
    env["LD_LIBRARY_PATH"] = ":".join(filter(None, [library_path, existing_library_path]))

    subprocess.run(
        [
            "uvx",
            "--from",
            "playwright",
            "playwright",
            "screenshot",
            "--browser",
            "chromium",
            "--viewport-size",
            "1600,1800",
            "--wait-for-selector",
            "text=Total Journeys Over Time",
            "--wait-for-timeout",
            "4000",
            "--full-page",
            APP_URL,
            str(OUTPUT_PATH),
        ],
        check=True,
        env=env,
    )


if __name__ == "__main__":
    main()
