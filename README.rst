=================================
 REANA demo example - BSM search
=================================

.. image:: https://img.shields.io/travis/reanahub/reana-demo-bsm-search.svg
   :target: https://travis-ci.org/reanahub/reana-demo-bsm-search

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/github/license/reanahub/reana-demo-bsm-search.svg
   :target: https://raw.githubusercontent.com/reanahub/reana-demo-bsm-search/master/LICENSE

About
=====

This `REANA <http://reanahub.io/>`_ demo example emulates typical Beyond
Standard Model (BSM) searches in particle physics data analyses. The signal and
background data is processed and fitted against a model. The example uses `ROOT
<https://root.cern.ch/>`_ analysis framework and `Yadage
<https://github.com/yadage>`_ computational workflow engine.

Analysis structure
==================

Making a research data analysis reproducible means to provide "runnable recipes"
addressing (1) where the input datasets are, (2) what software was used to
analyse the data, (3) which computing environment was used to run the software,
and (4) which workflow steps were taken to run the analysis.

1. Input dataset
---------------

In this example the signal and background data will be generated. Therefore
there is no explicit input file to be taken care of.

2. Analysis code
----------------

This example uses the `ROOT <https://root.cern.ch/>`_ analysis framework with
the custom user code located in the ``code`` directory:

- `generantuple.py <code/generantuple.py>`_ - generate N-tuples
- `hepdata_export.py <code/hepdata_export.py>`_ - prepare HepData submission
- `histogram.py <code/histogram.py>`_ - generate histogram
- `makews.py <code/makews.py>`_ - create channel samples
- `plot.py <code/plot.py>`_ - create final plots
- `select.py <code/select.py>`_ - apply shape variations

3. Compute environment
----------------------

In order to be able to rerun the analysis even several years in the future, we
need to "encapsulate the current compute environment", for example to freeze the
ROOT version our analysis is using. We shall achieve this by preparing a `Docker
<https://www.docker.com/>`_ container image for our analysis steps.

Some of the analysis steps will run in a pure `ROOT <https://root.cern.ch/>`_
analysis environment. We can use an already existing container image, for
example `reana-env-root6 <https://github.com/reanahub/reana-env-root6>`_, for
these steps.

Some of the other analysis tasks wil need ``hftools`` Python library installed
that our Python code needs. We can extend the ``reana-env-root6`` image to
install ``hftools`` and to include our own Python code. This can be achieved as
follows:

.. code-block:: console

   $ less environment/Dockerfile
   # Start from the ROOT6 base image:
   FROM reanahub/reana-env-root6

   # Install HFtools:
   RUN apt-get -y update && \
       apt-get -y install \
          python-pip \
          zip && \
       apt-get autoremove -y && \
       apt-get clean -y
   RUN pip install hftools

   # Mount our code:
   ADD code /code
   WORKDIR /code

We can build our analysis environment image and give it a name
``reanahub/reana-demo-bsm-search``:

.. code-block:: console

   $ docker build -f environment/Dockerfile -t reanahub/reana-demo-bsm-search .

We can push the image to the DockerHub image registry:

.. code-block:: console

   $ docker push reanahub/reana-demo-bsm-search

(Note that typically you would use your own username such as ``johndoe`` in
place of ``reanahub``.)

4. Analysis workflow
--------------------

This analysis example intends to emulate fully what is happening in a typical
BSM search analysis. This means a of computational steps with parallel execution
and merging of results.

We shall use the `Yadage <https://github.com/yadage>`_ workflow engine to
express the computational steps in a declarative manner. The `databkgmc.yml
<workflow/databkgmc.yml>`_ workflow defines the full pipeline defining various
data, signal, simulation, merging, fitting and plotting steps:

.. figure:: https://raw.githubusercontent.com/reanahub/reana-demo-bsm-search/master/docs/workflow-small.png
   :alt: workflow-small.png
   :align: center

The workflow inputs are ``nevents`` representing the number of events,
``mcweight`` representing the simulated data weight. They are defined in the
workflow file as parameters, for example:

.. code-block:: console

   $ less workflow/databkgmc.yml
   mcname: [mc1,mc2]
   mcweight: [0.01875,0.0125]  # [Ndata / Ngen * 0.2 * 0.15,  Ndata / Ngen * 0.2 * 0.1] = [10/16*0.03, 1/16 * 0.02]
   nevents:  [20000,20000,20000,20000,20000,20000,20000,20000]  #160k events / mc sample

Please see the `databkgmc.yml <workflow/databkgmc.yml>`_ workflow definition and
related `Yadage documentation <http://yadage.readthedocs.io/>`_.

Local testing with Yadage
=========================

We can check whether the example works locally using directly the `Yadage
<https://github.com/yadage>`_ workflow engine. We can install Yadage in a new
virtual environment:

.. code-block:: console

   $ mkvirtualenv yadage
   $ pip install yadage==0.13.5 yadage-schemas==0.7.16 packtivity==0.10.0

and run the analysis in a new ``_run`` directory:

.. code-block:: console

   $ yadage-run _run databkgmc.yml -t workflow
   2018-05-16 15:32:04,830 - yadage.utils - INFO - setting up backend multiproc:auto with opts {}
   2018-05-16 15:32:04,832 - packtivity.asyncbackends - INFO - configured pool size to 4
   2018-05-16 15:32:04,841 - yadage.utils - INFO - _run {}
   2018-05-16 15:32:05,070 - yadage.steering_object - INFO - no initialization data
   2018-05-16 15:32:05,070 - adage.pollingexec - INFO - preparing adage coroutine.
   2018-05-16 15:32:05,071 - adage - INFO - starting state loop.
   ...
   ...
   2018-05-16 15:34:46,824 - adage - INFO - adage state loop done.
   2018-05-16 15:34:46,825 - adage - INFO - execution valid. (in terms of execution order)
   2018-05-16 15:34:46,921 - adage.controllerutils - INFO - no nodes can be run anymore and no rules are applicable
   2018-05-16 15:34:46,921 - adage - INFO - workflow completed successfully.

The analysis will run for about two minutes and will produce two final plots:

.. code-block:: console

   $ ls -l _run/plot/*.pdf
   -rw-r--r-- 1 root root 19193 May 16 15:34 _run/plot/postfit.pdf
   -rw-r--r-- 1 root root 19450 May 16 15:34 _run/plot/prefit.pdf

.. figure:: https://raw.githubusercontent.com/reanahub/reana-demo-bsm-search/master/docs/postfit.png
   :alt: postfit.png
   :align: center

Running the example on REANA cloud
==================================

**FIXME**

Contributors
============

The list of contributors in alphabetical order:

- `Lukas Heinrich <https://orcid.org/0000-0002-4048-7584>`_ <lukas.heinrich@gmail.com>
- `Tibor Simko <https://orcid.org/0000-0001-7202-5803>`_ <tibor.simko@cern.ch>
