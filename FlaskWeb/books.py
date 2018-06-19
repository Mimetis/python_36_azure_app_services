import flask
import pandas as pd
from flask import request, jsonify, make_response, abort
from FlaskWeb import app


# Create some test data for our catalog in the form of a list of dictionaries.
books = [
    {'id': 0,
     'title': 'A Fire Upon the Deep',
     'author': 'Vernor Vinge',
     'first_sentence': 'The coldsleep itself was dreamless.',
     'year_published': '1992'},
    {'id': 1,
     'title': 'The Ones Who Walk Away From Omelas',
     'author': 'Ursula K. Le Guin',
     'first_sentence': 'With a clamor of bells that set the swallows soaring, the Festival of Summer came to the city Omelas, bright-towered by the sea.',
     'published': '1973'},
    {'id': 2,
     'title': 'Dhalgren',
     'author': 'Samuel R. Delany',
     'first_sentence': 'to wound the autumnal city.',
     'published': '1975'}
]


# A route to return all of the available entries in our catalog.
@app.route('/api/v1/books/all', methods=['GET'])
def api_all():
    return jsonify(books)


@app.route('/api/v1/books/<int:bookId>', methods=['GET'])
def get_task(bookId):
    book = [book for book in books if book['id'] == bookId]
    if len(book) == 0:
        abort(404)
    return jsonify(book[0])


# A route to return all of the available entries in our catalog.
@app.route('/api/v1/pandas', methods=['GET'])
def api_pandas():
    df = pd.DataFrame({'col1': [1]})
    col1 = df.columns[0]
    return jsonify(col1)


@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)
