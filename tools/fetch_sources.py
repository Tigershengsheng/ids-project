"""Fetch public source material; all statistical analysis is performed in R."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import io
import json
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SOURCES = ROOT / "docs" / "sources"
SOURCES.mkdir(parents=True, exist_ok=True)

def get(url, timeout=18):
    request = urllib.request.Request(url, headers={"User-Agent": "IDS-coursework-source-verification/1.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read(12_000_000)

def dataset():
    url = "https://archive.ics.uci.edu/static/public/697/predict+students+dropout+and+academic+success.zip"
    archive_bytes = get(url)
    raw = zipfile.ZipFile(io.BytesIO(archive_bytes)).read("data.csv")
    (DATA / "data.csv").write_bytes(raw)
    return {"kind": "dataset", "url": url, "csv_sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}

def metadata():
    url = "https://archive.ics.uci.edu/api/dataset?id=697"
    raw = get(url)
    obj = json.loads(raw)
    (SOURCES / "uci-metadata.json").write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"kind": "metadata", "url": url, "bytes": len(raw)}

def paper():
    urls = [
        "https://mdpi-res.com/d_attachment/data/data-07-00146/article_deploy/data-07-00146.pdf",
        "https://dorsu.edu.ph/faculty/jscabrera/wp-content/uploads/2022/12/data-07-00146.pdf",
    ]
    errors = []
    for url in urls:
        try:
            raw = get(url, timeout=12)
            if not raw.startswith(b"%PDF"):
                raise ValueError("The response is not a PDF")
            (SOURCES / "Realinho-2022-data-07-00146.pdf").write_bytes(raw)
            return {"kind": "original_data_paper", "url": url, "doi": "10.3390/data7110146", "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}
        except Exception as exc:
            errors.append({"url": url, "error": str(exc)})
    return {"kind": "original_data_paper", "errors": errors}

if __name__ == "__main__":
    with ThreadPoolExecutor(max_workers=3) as executor:
        jobs = [executor.submit(task) for task in (dataset, metadata, paper)]
        records = []
        for job in jobs:
            try:
                records.append(job.result())
            except Exception as exc:
                records.append({"error": str(exc)})
    result = {"access_date": "2026-11-05", "retrieval_utc": datetime.now(timezone.utc).isoformat(), "records": records}
    (SOURCES / "retrieval.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
