import csv
import json
import tempfile
import unittest
from pathlib import Path

import etl


class EtlTests(unittest.TestCase):
    def test_invalid_values_missing_values_duplicates_and_conflict(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.csv"
            facts = root / "facts.pl"
            summary_path = root / "summary.json"
            conflicts = root / "conflicts.json"
            rows = []
            base = {
                "Name": "Valid", "Platform": "P", "Year_of_Release": "2000",
                "Genre": "Action", "Publisher": "Pub", "NA_Sales": "0",
                "EU_Sales": "0", "JP_Sales": "0", "Other_Sales": "0",
                "Global_Sales": "1", "Critic_Score": "80", "Critic_Count": "10",
                "User_Score": "8", "User_Count": "50", "Developer": "Dev",
                "Rating": "E",
            }
            rows.extend([base.copy(), base.copy()])
            conflict = base.copy()
            conflict.update(Name="Conflict", Global_Sales="2")
            conflict_2 = conflict.copy()
            conflict_2["Global_Sales"] = "0.01"
            rows.extend([conflict, conflict_2])
            invalid = base.copy()
            invalid.update(Name="Invalid", Critic_Count="10.9",
                           User_Count="-0.5", Global_Sales="-5",
                           Year_of_Release="2000.5", User_Score="nan")
            rows.append(invalid)
            with source.open("w", encoding="utf-8", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=etl.SOURCE_FIELDS)
                writer.writeheader()
                writer.writerows(rows)

            summary = etl.run(source, facts, summary_path, conflicts)

            self.assertEqual(summary["records_read"], 5)
            self.assertEqual(summary["records_kept"], 2)
            self.assertEqual(summary["removed_by_reason"]["exact_duplicate_selected_fields"], 1)
            self.assertEqual(summary["removed_by_reason"]["conflicting_identity"], 2)
            self.assertGreater(summary["problem_counts"]["invalid_Critic_Count"], 0)
            self.assertGreater(summary["problem_counts"]["invalid_Global_Sales_range"], 0)
            report = json.loads(conflicts.read_text(encoding="utf-8"))
            self.assertEqual(len(report), 1)
            self.assertEqual(len(report[0]["source_rows"]), 2)
            self.assertEqual(sum(1 for line in facts.read_text().splitlines()
                                 if line.startswith("jogo(")), 2)


if __name__ == "__main__":
    unittest.main()
