import pandas as pd
from sklearn.metrics import accuracy_score

from mlebench.competitions.utils import prepare_for_accuracy_metric


def grade(submission: pd.DataFrame, answers: pd.DataFrame) -> float:
    accuracy_inputs = prepare_for_accuracy_metric(
        submission=submission, answers=answers, target_column="category_id", id_column="_id"
    )
    return accuracy_score(**accuracy_inputs)