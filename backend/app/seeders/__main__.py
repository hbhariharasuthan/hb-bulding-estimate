from __future__ import annotations

import argparse

from app.seeders import SEEDERS


def main() -> None:
    parser = argparse.ArgumentParser(description="Run database seeders.")
    parser.add_argument(
        "--seeder",
        choices=["all", *SEEDERS.keys()],
        default="all",
        help="Run one seeder or all seeders.",
    )
    args = parser.parse_args()

    if args.seeder == "all":
        for name, func in SEEDERS.items():
            print(f"Running seeder: {name}")
            func()
        return

    print(f"Running seeder: {args.seeder}")
    SEEDERS[args.seeder]()


if __name__ == "__main__":
    main()

