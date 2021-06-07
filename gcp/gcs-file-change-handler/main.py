import os
from google.cloud import firestore

project_id = os.environ["GCP_PROJECT"]


def handle_new_file(event, context):
  """
    Appends the name of the file added to the Cloud Storage bucket
    in the "files" array of the "new" document in Firestore.
    :params event: Event payload
    :type event: dict
    :params context: Event metadata
    :type context: google.cloud.functions.Context
    """
    file_path = "gs://%s/%s" % (event["bucket"], event["name"])
    db = firestore.Client(project=project_id)
    db.collection("jobs").document("new").set(
        {"files": firestore.ArrayUnion([file_path])}, merge=True)
    print("Added file: %s" % file_path)
