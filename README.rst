============================
 REANA example - BSM search
============================

.. image:: https://img.shields.io/travis/reanahub/reana-demo-bsm-search.svg
   :target: https://travis-ci.org/reanahub/reana-demo-bsm-search

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/github/license/reanahub/reana-demo-bsm-search.svg
   :target: https://raw.githubusercontent.com/reanahub/reana-demo-bsm-search/master/LICENSE

About
=====

This `REANA <http://reanahub.io/>`_ reproducible analysis example emulates
typical Beyond Standard Model (BSM) searches in particle physics data analyses.
The signal and background data is processed and fitted against a model. The
example uses `ROOT <https://root.cern.ch/>`_ analysis framework and `Yadage
<https://github.com/yadage>`_ computational workflow engine.

Analysis structure
==================

Making a research data analysis reproducible basically means to provide
"runnable recipes" addressing (1) where is the input data, (2) what software was
used to analyse the data, (3) which computing environments were used to run the
software and (4) which computational workflow steps were taken to run the
analysis. This will permit to instantiate the analysis on the computational
cloud and run the analysis to obtain (5) output results.

1. Input data
-------------

In this example, the input datasets representing the collision and simulated
data will be generated. Therefore there is no explicit input data to be taken
care of.

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

The workflow inputs include:

- ``nevents`` representing the number of collision events
- ``mcweight`` representing the simulated data weight

The parameters are defined in the workflow file, for example:

.. code-block:: console

   $ head -8 workflow/databkgmc.yml
   stages:
     - name: all_bkg_mc
       scheduler:
         scheduler_type: singlestep-stage
         parameters:
           mcname: [mc1,mc2]
           mcweight: [0.01875,0.0125]  # [Ndata / Ngen * 0.2 * 0.15,  Ndata / Ngen * 0.2 * 0.1] = [10/16*0.03, 1/16 * 0.02]
           nevents:  [40000,40000,40000,40000]  #160k events / mc sample

Please see the `databkgmc.yml <workflow/databkgmc.yml>`_ workflow definition and
related `Yadage documentation <http://yadage.readthedocs.io/>`_.

5. Output results
-----------------

The analysis produces the following post-fit output plot:

.. figure:: https://raw.githubusercontent.com/reanahub/reana-demo-bsm-search/master/docs/postfit.png
   :alt: postfit.png
   :align: center

Local testing
=============

*Optional*

If you would like to test the analysis locally (i.e. outside of the REANA
platform), you can proceed as follows:

.. code-block:: console

   $ # this analysis example uses yadage; let's install it
   $ mkvirtualenv yadage
   $ pip install yadage==0.13.5 yadage-schemas==0.7.16 packtivity==0.10.0
   $ # we can now run the analysis workflow
   $ sudo yadage-run _run workflow/databkgmc.yml
   $ # let up check output files
   $ ls -l _run/plot/*.pdf
   -rw-r--r-- 1 root root 19193 May 16 15:34 _run/plot/postfit.pdf
   -rw-r--r-- 1 root root 19450 May 16 15:34 _run/plot/prefit.pdf

Running the example on REANA cloud
==================================

First we need to create a `reana.yaml <reana.yaml>`_ file describing the
structure of our analysis with its inputs, the code, the runtime environment,
the workflow and the expected outputs:

.. code-block:: yaml

   version: 0.2.0
   inputs:
    parameters:
       nevents: 160000
   outputs:
     files:
      - outputs/plot/postfit.pdf
   environments:
    - type: docker
      image: reanahub/reana-demo-bsm-search
   workflow:
     type: yadage
     file: workflow/databkgmc.yml

We proceed by installing the REANA command-line client:

.. code-block:: console

    $ mkvirtualenv reana-client
    $ pip install reana-client

We should now connect the client to the remote REANA cloud where the analysis
will run. We do this by setting the ``REANA_SERVER_URL`` environment variable:

.. code-block:: console

    $ export REANA_SERVER_URL=https://reana.cern.ch/

Note that if you `run REANA cluster locally
<http://reana-cluster.readthedocs.io/en/latest/gettingstarted.html#deploy-reana-cluster-locally>`_
on your laptop, you would do:

.. code-block:: console

   $ eval $(reana-cluster env)

Let us test the client-to-server connection:

.. code-block:: console

   $ reana-client ping
   Server is running.

We proceed to create a new workflow instance:

.. code-block:: console

    $ reana-client workflow create
    workflow.1
    $ export REANA_WORKON=workflow.1

We can now start the workflow execution:

.. code-block:: console

    $ reana-client workflow start
    workflow.1 has been started.

After several minutes the workflow should be successfully finished. Let us query
its status:

.. code-block:: console

    $ reana-client workflow status
    NAME       RUN_NUMBER   ID                                     USER                                   ORGANIZATION   STATUS
    workflow   1            0df60c85-9d84-402e-814c-0595fe5fd439   00000000-0000-0000-0000-000000000000   default        finished

We can list the output files:

.. code-block:: console

    $ reana-client outputs list | head -3
    NAME                                                 SIZE      LAST-MODIFIED
    plot/postfit.pdf                                     19404     2018-06-07 23:44:53.830441+00:00
    plot/prefit.pdf                                      19425     2018-06-07 23:44:53.830441+00:00

We finish by downloading generated plots:

.. code-block:: console

    $ reana-client outputs download plot/postfit.pdf
    File plot/postfit.pdf downloaded to ./outputs/

Contributors
============

The list of contributors in alphabetical order:

- `Lukas Heinrich <https://orcid.org/0000-0002-4048-7584>`_ <lukas.heinrich@gmail.com>
- `Tibor Simko <https://orcid.org/0000-0001-7202-5803>`_ <tibor.simko@cern.ch>
