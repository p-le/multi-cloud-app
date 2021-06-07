import datetime
import time
import os
from google.cloud import pubsub_v1


# Reference for message:
# https://github.com/googleapis/python-pubsub/blob/master/google/cloud/pubsub_v1/proto/pubsub.proto
def main(project: str, subcription: str):
    """Continuously pull messages from subsciption"""
    with pubsub_v1.SubscriberClient() as subscriber:
        subscription_path = subscriber.subscription_path(project, subcription)
        print(f'[{datetime.datetime.now()}] Pulling messages from  from Pub/Sub project={project} subcription={subcription}')
        while True:
            response = subscriber.pull(
                request={
                    "subscription": subscription_path,
                    "max_messages": 10,
                }
            )
            for msg in response.received_messages:
                print("[{0}] Received message: ID={1} Data={2} Attributes={3}".format(
                        datetime.datetime.now(),
                        msg.message.message_id,
                        msg.message.data,
                        msg.message.attributes))
                process(msg.message)

            ack_ids = [msg.ack_id for msg in response.received_messages]
            if len(ack_ids) > 0:
                subscriber.acknowledge(
                    request={
                        "subscription": subscription_path,
                        "ack_ids": ack_ids,
                    }
                )
            time.sleep(5)
            print(f'[{datetime.datetime.now()}] Pulling messages from  from Pub/Sub project={project} subcription={subcription}')


def process(message):
    """Process received message"""
    print("[{0}] Processing: {1}".format(datetime.datetime.now(), message.message_id))
    time.sleep(1)
    print("[{0}] Processed: {1}".format(datetime.datetime.now(), message.message_id))


if __name__ == '__main__':
    project = os.getenv('PUBSUB_PROJECT_ID')
    subcription = os.getenv('PUBSUB_SUBSCRIPTION')
    main(project, subcription)
