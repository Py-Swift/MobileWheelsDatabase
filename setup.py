"""
Setup configuration for mkdocs-mobilewheels plugin
"""

from setuptools import setup, find_packages

with open("USAGE.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="mkdocs-mobilewheelsdb-plugin",
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
        'mkdocs_mobilewheelsdb': [
            'assets/*',
            'templates/*',
        ],
    },
    install_requires=[
        'mkdocs>=1.4.0',
        'mkdocs-material>=9.7.0',
        'pymdown-extensions>=10.3',
    ],
    entry_points={
        'mkdocs.plugins': [
            'mobilewheelsdb = mkdocs_mobilewheelsdb.plugin:MobileWheelsPlugin',
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
    python_requires=">=3.13",
)
