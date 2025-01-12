from setuptools import setup, find_packages

setup(
    name='New_Project',
    version='1.0.0',
    description='project',
    author='Simiran',
    author_email='simirankaur14@gmail.com',
    packages=find_packages(),  # Automatically finds and includes all packages
    install_requires=[
'asgiref==3.8.1',
'blinker==1.9.0',
'certifi==2024.12.14',
'charset-normalizer==3.4.0',
'click==8.1.7',
'colorama==0.4.6',
'Django==5.1.4',
'Flask==3.1.0',
'idna==3.10',
'itsdangerous==2.2.0',
'Jinja2==3.1.4',
'MarkupSafe==3.0.2',
'requests==2.32.3',
'sqlparse==0.5.3',
'tzdata==2024.2',
'urllib3==2.2.3',
'Werkzeug==3.1.3',
'requests>=2.25.1'
    ],
    python_requires='>=3.6',
)
