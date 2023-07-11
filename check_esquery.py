#!/usr/bin/env python3
#####################################################################################
# check_esquery                                                                     #
# Checks for the existence of a search term in Elasticsearch. Useful for detecting  #
# in application logs.                                                              #
# Tom Vernon 29/09/2022                                                             #
#####################################################################################
import argparse
import sys
from elasticsearch import Elasticsearch
from datetime import date

# NAGIOS return codes:
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

def get_args():
    """
    Supports the command-line arguments listed below.
    """
    parser = argparse.ArgumentParser(description="Elastic Term Check")
    parser._optionals.title = "Options"
    parser.add_argument('-t', '--term', nargs=1, required=True,
                        help='Term to search for', dest='search_term', type=str)
    parser.add_argument('-d', '--duration', nargs=1, required=True,
                        help='Duration in minutes to search', dest='search_duration', type=int)
    parser.add_argument('-s', '--server', nargs=1, required=True,
                        help='Server address of Elasticsearch', dest='server_address', type=str)
    parser.add_argument('-u', '--username', nargs=1, required=True,
                        help='User of Elasticsearch', dest='username', type=str)
    parser.add_argument('-p', '--password', nargs=1, required=True,
                        help='Password of Elasticsearch', dest='password', type=str)
    args = parser.parse_args()
    return args

def check_elastic(args):
    """
    Queries Elasticsearch for the term
    """
    
    index_date = date.today().strftime("%Y.%m.%d")

    es_query = {
        "bool": {
            "must": {
                "query_string": {
                    "query": args.search_term[0]
                }
            },
            "filter": {
                "range": {
                    "@timestamp": {
                        "gte": f"now-{args.search_duration[0]}m",
                        "lte": "now"
                    }
                }
            }
        }
    }

    es = Elasticsearch(args.server_address[0],
                       basic_auth=(args.username[0], args.password[0]))
    res = es.search(index=f"filebeat-*-{index_date}", query=es_query)
    return res

def main():

    # Handling arguments
    args = get_args()

    # Check Elastic
    res = check_elastic(args)

    # Generate output
    if res['hits']['total']['value'] == 0:
        print(f"OK: Term {args.search_term[0]} was not found in {args.search_duration[0]} minutes")
        sys.exit(OK)
    elif res['hits']['total']['value'] >= 1:
        print(f"WARN: Term {args.search_term[0]} was found {str(res['hits']['total']['value'])} times in {args.search_duration[0]} minutes")
        sys.exit(WARNING)
    else:
        print("Something went wrong")
        sys.exit(UNKNOWN)

if __name__ == "__main__":
    main()
