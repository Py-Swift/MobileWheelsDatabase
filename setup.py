"""
Setup configuration for mkdocs-mobilewheels plugin
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="mkdocs-mobilewheels",
    version="0.1.0",
    author="Py-Swift",
    author_email="",
    description="MkDocs plugin for Python package compatibility search with WASM-powered SQLite",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Py-Swift/MobileWheelsDatabase",
    packages=find_packages(),
    include_package_data=True,
    package_data={
        'mkdocs_mobilewheels': [
            'assets/*',
            'templates/*',
        ],
    },
    install_requires=[
        'mkdocs>=1.4.0',
    ],
    entry_points={
        'mkdocs.plugins': [
            'mobilewheels = mkdocs_mobilewheels.plugin:MobileWheelsPlugin',
        ]
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
)
