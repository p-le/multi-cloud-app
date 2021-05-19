# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
import os
from typing import Dict

import sqlalchemy
from sqlalchemy.orm import close_all_sessions
from sqlalchemy.pool import NullPool, QueuePool

import utils.credentials as credentials
from utils.middleware import logger

# This global variable is declared with a value of `None`, instead of calling
# `init_connection_engine()` immediately, to simplify testing. In general, it
# is safe to initialize your database connection pool when your script starts
# -- there is no need to wait for the first request.
db = None


def init_connection_engine() -> Dict[str, int]:
    if os.getenv("TRAMPOLINE_CI", None):
        logger.info("Using NullPool for testing")
        db_config = {"poolclass": NullPool}
    else:
        db_config = {
            "poolclass": QueuePool,
            "connect_args": {
                "auth_plugin": "mysql_native_password"
            }
        }

    if os.environ.get("DB_HOST"):
        return init_tcp_connection_engine(db_config)
    else:
        return init_unix_connection_engine(db_config)


def init_tcp_connection_engine(db_config: Dict[str, str]) -> sqlalchemy.engine.base.Engine:
    creds = credentials.get_cred_config()
    db_user = creds["DB_USER"]
    db_pass = creds["DB_PASSWORD"]
    db_name = creds["DB_NAME"]
    db_host = creds["DB_HOST"]

    # Extract host and port from db_host
    host_args = db_host.split(":")
    db_hostname, db_port = host_args[0], int(host_args[1])

    pool = sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL(
            drivername="mysql+mysqlconnector",
            username=db_user,
            password=db_pass,
            host=db_hostname,
            port=db_port,
            database=db_name,
            query={
                "auth_plugin": "mysql_native_password"
            }
        ),
        **db_config,
    )
    logger.info("Database engine initialised from tcp connection")
    return pool


def init_unix_connection_engine(db_config: Dict[str, str]) -> sqlalchemy.engine.base.Engine:
    creds = credentials.get_cred_config()
    db_user = creds["DB_USER"]
    db_pass = creds["DB_PASSWORD"]
    db_name = creds["DB_NAME"]
    db_socket_dir = creds.get("DB_SOCKET_DIR", "/cloudsql")
    cloud_sql_connection_name = creds["CLOUD_SQL_CONNECTION_NAME"]

    pool = sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL(
            drivername="mysql+mysqlconnector",
            username=db_user,
            password=db_pass,
            database=db_name,
            query={
                "auth_plugin": "mysql_native_password",
                "unix_socket": f"{db_socket_dir}/{cloud_sql_connection_name}"
            },
        ),
        **db_config,
    )
    logger.info("Database engine initialised from unix conection")

    return pool


def create_tables() -> None:
    logger.info("Creating tables")
    global db
    db = db or init_connection_engine()
    # Create pet_votes table if it doesn't already exist
    with db.connect() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS pet_votes"
            "( vote_id SERIAL NOT NULL, "
            "time_cast timestamp NOT NULL, "
            "candidate VARCHAR(6) NOT NULL, "
            "uid VARCHAR(128) NOT NULL, "
            "PRIMARY KEY (vote_id)"
            ");"
        )


def get_index_context() -> Dict:
    votes = []
    with db.connect() as conn:
        # Execute the query and fetch all results
        recent_votes = conn.execute(
            "SELECT candidate, time_cast FROM pet_votes "
            "ORDER BY time_cast DESC LIMIT 5"
        ).fetchall()
        # Convert the results into a list of dicts representing votes
        for row in recent_votes:
            votes.append(
                {
                    "candidate": row[0],
                    "time_cast": row[1],
                }
            )
        stmt = sqlalchemy.text(
            "SELECT COUNT(vote_id) FROM pet_votes WHERE candidate=:candidate"
        )
        # Count number of votes for cats
        cats_result = conn.execute(stmt, candidate="CATS").fetchone()
        cats_count = cats_result[0]
        # Count number of votes for dogs
        dogs_result = conn.execute(stmt, candidate="DOGS").fetchone()
        dogs_count = dogs_result[0]
    return {
        "dogs_count": dogs_count,
        "recent_votes": votes,
        "cats_count": cats_count,
    }


def save_vote(team: str, uid: str, time_cast: datetime.datetime) -> None:
    # Preparing a statement before hand can help protect against injections.
    stmt = sqlalchemy.text(
        "INSERT INTO pet_votes (time_cast, candidate, uid)"
        " VALUES (:time_cast, :candidate, :uid)"
    )

    # Using a with statement ensures that the connection is always released
    # back into the pool at the end of statement (even if an error occurs)
    with db.connect() as conn:
        conn.execute(stmt, time_cast=time_cast, candidate=team, uid=uid)
    logger.info("Vote for %s saved.", team)


def shutdown() -> None:
    # Find all Sessions in memory and close them.
    close_all_sessions()
    logger.info("All sessions closed.")
    # Each connection was released on execution, so just formally
    # dispose of the db connection if it's been instantiated
    if db:
        db.dispose()
        logger.info("Database connection disposed.")
