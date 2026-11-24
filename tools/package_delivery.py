"""Package the verified HTML, source, slides and optional bilingual rehearsal material."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import shutil
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[1]
PPT = "output/powerpoint/Student_Dropout_Presentation.pptx"
PDF = "output/reading-pdfs/"
PAIRS = ["presentation", "report", "investigation", "speaker-notes", "study-guide"]
HELPERS = ["package_delivery.py", "capture_slides.mjs", "prepare_powerpoint.py",
           "build_powerpoint.mjs", "finish_powerpoint_spacing.py", "finalize_powerpoint.mjs",
           "fetch_sources.py", "show_project_data.R"]
COURSE_DOCS = ["analysis-plan", "course-map", "source-notes", "slide-outline",
               "data-to-viz-review", "learning-process", "regression-course-update",
               "requirements-checklist"]


def digest(file):
    return sha256(file.read_bytes()).hexdigest()


def package(destination, include_rehearsal):
    shared = ["presentation.html", "report.html", PPT, PDF + "01_Presentation.pdf",
              PDF + "02_Speaker_Notes.pdf"]
    source = [".Rprofile", "README.md", "repository-status.md", "student-dropout-final.Rproj",
              "slides.css", "render_project.R", "verify_project.R", "vendor/remark-latest.min.js",
              "docs/revision-review.md", "docs/delivery-policy.md", "data/data.csv", "data/README.md",
              "results/analysis.rds", "results/fitted-models.rds", "results/stage-two-validation.json",
              "results/frozen-configuration.json", "results/script-timing.json",
              "results/session-info.txt", "results/verification.txt", "results/verification.json"]
    for name in PAIRS:
        source.extend(name + suffix for suffix in [".Rmd", ".html"])
    for name in COURSE_DOCS:
        source.extend("docs/" + name + suffix for suffix in [".md", ".html"])
    source.extend("tools/" + item for item in HELPERS)
    for pattern in ["R/*.R", "docs/sources/*", "docs/course-template/*", "img/*",
                    "figures/*.png", "figures/*.pdf", "results/*.csv"]:
        source.extend(p.relative_to(ROOT).as_posix() for p in ROOT.glob(pattern) if p.is_file())
    if include_rehearsal:
        shared.extend([PDF + "03_中文排练稿.pdf", PDF + "04_Defence_Question_Bank.pdf"])
        source.extend(["private-study/README.md", "private-study/排练与理解.md",
                       "private-study/defence-questions.md", "private-study/本轮修改对照.md",
                       "tools/make_reading_pdfs.py", "tools/make_defence_pdf.py"])
    members = sorted(set(source + shared))
    for name in members:
        if not (ROOT / name).is_file():
            raise FileNotFoundError(name)
    destination.mkdir(parents=True, exist_ok=True)
    bundle = destination / "IDS_Final_Project.zip"
    temporary = bundle.with_suffix(".zip.tmp")
    with ZipFile(temporary, "w", compression=ZIP_DEFLATED, compresslevel=6) as z:
        for name in members:
            z.write(ROOT / name, "student-dropout-final/" + name)
    with ZipFile(temporary) as z:
        if z.testzip() is not None:
            raise ValueError("ZIP integrity check failed")
        for name in members:
            if z.read("student-dropout-final/" + name) != (ROOT / name).read_bytes():
                raise ValueError("ZIP verification failed for " + name)
    temporary.replace(bundle)
    files = [bundle]
    for name in shared:
        target = destination / Path(name).name
        shutil.copyfile(ROOT / name, target)
        if digest(target) != digest(ROOT / name):
            raise ValueError("Copy verification failed for " + name)
        files.append(target)
    manifest = {p.name: {"bytes": p.stat().st_size, "sha256": digest(p)} for p in files}
    (destination / "delivery-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Verified {len(members)} ZIP entries and {len(shared)} standalone files.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path, help="folder for the shareable files")
    parser.add_argument("--include-rehearsal", action="store_true",
                        help="include the local bilingual team handouts")
    args = parser.parse_args()
    package(args.destination.resolve(), args.include_rehearsal)
