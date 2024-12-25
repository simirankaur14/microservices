from flask import Flask,render_template
import requests

app = Flask(__name__)

@app.route('/<name>')
def hello_flask(name):
   if name == 'python':
       return 'Hello Python'
   else:
       return 'Hello Flask %s, How are you' % name
@app.route('/')
def hello_python():
   return 'Hello Python'

@app.route('/htmlpage/')
def hello_html():
    data = get_ip()
    return render_template('index.html', value = data)

@app.route('/ip/')
def get_ip():
    response = requests.get('https://api.ipify.org')
    return response.text

if __name__ == '__main__':
    app.run(debug=True)