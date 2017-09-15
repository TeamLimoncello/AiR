from setuptools import setup

setup(
    name='air_server',
    packages=['server'],
    include_package_data=True,
    install_requires=[
        'flask',
        'pillow',
        'celery',
        'requests',
        'pyproj',
    ],
)
