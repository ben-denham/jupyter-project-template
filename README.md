# Jupyter Project Template

A Docker-based project setup for Python projects centred around
Jupyter notebooks. Ideal for data science projects.

## Features

* Run a local [JupyterLab](https://jupyter.org/) server.
* Reference custom Python modules from your notebooks for better code
  organisation.
* Includes a Makefile to organise commonly run commands.
* Runs all code inside [Docker](https://www.docker.com/) containers to minimise host
  dependencies.
* Deploy notebooks via
  [Voilà](https://github.com/voila-dashboards/voila) with
  [Docker](https://www.docker.com/).
* Basic setup for managing large data files.

## Project Structure

* `lib/` - Python modules containing the primary source code.
* `notebooks/` - `.ipynb` notebooks used during development.
* `script_notebooks/` - `.py` notebooks that are version-controlled
  and paired with the `.ipynb` files in `notebooks/`
* `app/` - Files for the deployable Voilà application.
* `tests/` - Tests for the Python modules in `lib/`.
* `data/` - Directory for storing development data files referenced by
  `notebooks/`.

## Dependencies

In order to run this project, you must have the following dependencies
installed on your host:

* [Docker Community Edition](https://docs.docker.com/get-docker/) (>= 17.09)
* [Docker Compose](https://docs.docker.com/compose/install/) (>= 1.17)
  (Included with Docker Desktop on Mac/Windows)
* [Make](https://www.gnu.org/software/make/) (technically optional if
  you don't mind running the commands in the Makefile directly)

**Note:** If you use [Git bash](https://git-scm.com/downloads) on
Windows and also
[install `make`](https://gist.github.com/evanwill/0207876c3243bbb6863e65ec5dc3f058)
into Git bash, then you should be able to run this project on Windows.

## Development

1. Ensure the dependencies listed above are installed.
2. Change the `BASE_IMAGE_NAME` at the top of the `Makefile`.
3. Run `make dev` in this directory.
   * This will perform all Docker image build steps and dependency
     installations every time you run it, so that you can never forget
     to rebuild. The first time you run this, it make take some time
     for the base Docker image and other dependencies to be
     downloaded.
4. To develop with JupyterLab:
   1. Browse to http://localhost:8888 and enter the token displayed in
      the terminal (or just follow the link in the terminal).
   2. Work in the development Python notebooks inside `notebooks/`,
      with the ability to import code from your own custom Python
      modules and their dependencies, e.g.: `from mypymodule import stuff`.
5. To view the development Voila server:
   1. Browse to http://localhost:8866
   2. You will see a list of available application notebooks to run
      from `app/voila-notebooks` (you may add/edit these notebooks
      through JupyterLab).

## Python Module Development

In order to better structure and share Python code between Jupyter
notebooks, you should primarily add code to custom Python
packages/modules contained in the `lib/` directory. An example
`mypymodule` is provided, but you can add more directories - if you
do, just make sure to update the `packages` list in the
`pyproject.toml`.

It is recommended that you automatically reload your Python modules in
Jupyter notebooks so that any changes you make immediately take effect
without restarting the notebook kernel. To do so, include and run the
following cell at the top of each notebook:

```
%load_ext autoreload
%autoreload 2
```

### Dependencies

To add Python module dependencies:

1. Start a shell inside a dev Docker container: `make run-bash service=jupyter`
2. Use poetry to add the dependency: `poetry add <your-dependency>`

When `make dev` is run it will alway ensure all dependencies are
installed, and you can also manually install dependencies by running:
`make deps`.

If you have poetry installed on your host, your `poetry config
cache-dir` will be mounted into the Docker container in order to avoid
re-downloading dependencies across projects.

To update the versions of Python packages in use, run: `make
deps-update`.

### Code Checking

Running `make check` will perform the following checks:

#### Linting

You can run [flake8](http://flake8.pycqa.org/en/latest/) linting on
your modules with: `make lint`.

#### Testing

You can run [pytest](https://docs.pytest.org/en/latest/) unit tests
linting contained in your modules with: `make test`.

An HTML code-coverage reported will be generated for each module at:
`<module-dir>/test/coverage/index.html`.

#### Type-Checking

You can run [mypy](https://mypy.readthedocs.io/en/stable/)
type-checking on your modules with: `make mypy`.

## Exporting Notebooks

You can run `make notebook-export` to generate HTML copies of your
notebooks in `notebooks/export`, with code-cell toggling.

## Deployment

If you want to package up the Voilà app as a self-contained Docker
image with no external dependencies, you can build and export a
self-contained Docker image to move to that host:

1. Build the production application image: `make prod-build`
2. Test the app as it will run in production: `make prod-run`
  * If files needed to run are missing, ensure they are added in the
    `prod_image` section of the Dockerfile.
  * To debug the contents of the image, use `make prod-run-bash` and
    `make prod-run-sudo-bash`.
1. Run `make prod-export-image` to export the production Docker image.
2. Copy the `app/images/` directory to the same location within the
   project on the target host.
3. Run `make prod-import-image` on the target host.
4. Run `make prod-run` on the target host.

## Managing Data

It is recommended that you store your large data files in the `data/`
directory so that they are not committed to your Git repository and
not transmitted to the Docker daemon during image builds (see
[.dockerignore](#dockerignore)).

In order to not commit the outputs of notebooks cells to your Git
repository, `.ipynb` files in `notebooks/` are not tracked in Git.
Instead, [jupytext](https://jupytext.readthedocs.io/en/latest/) is
used to sync notebooks with `.py` files that are tracked in Git (which
have the added benefit of producing simpler diffs and merges).

* Any time you create/save a notebook under `notebooks/` in
  JupyterLab, a corresponding percent-style `.py` file under
  `script_notebooks/` will be created/updated.
* When opening a notebook under `notebooks/` in JupyterLab, cell
  inputs will be loaded from whichever of the `.ipynb` or `.py` was
  updated most recently, and cell outputs will only be retained for
  cells when the cell input has not changed.
* You can run `make notebook-sync` manually to sync the contents of
  `notebooks/` and `script_notebooks/`.
* This configuration is managed in the `[tool.jupytext.formats]`
  section of `pyproject.toml`.

## Notes About Docker

### Opening a Shell

If you would like to open a bash shell inside the Docker container
running the Jupyter notebook server or Voila app, use: `make bash
service=<service>` or `make sudo-bash service=<service>` (where
`<service>` is either `app` or `jupyter`). If `make dev` is not
currently running, you can instead use `make run-bash
service=<service>` or `make run-sudo-bash service=<service>`.

### System Dependencies and Other OS Configurations

To install system packages or otherwise alter the Docker image's
operating system, you can make changes in the Dockerfile. An example
section that will allow you to install `apt` packages is included.

### Changing Dev Server Ports

You can change the `ports` entry in `docker-compose.yml` for either
`app` or `jupyter`. For example, to change the `jupyter` port, set its
value to `'127.0.0.1:YOURPORT:8888'`, then re-run `make dev`.

### .dockerignore

Whenever the Docker image is rebuilt (after certain files are
changed), Docker will transmit the contents of this directory to the
Docker daemon.

To speed up build times, you should add an entry to the
`.dockerignore` file for any directories containing large files you do
not need to be included in the Docker image at build time.

### Managing Docker Image Storage

When Docker builds new versions of its images, it does not delete the
old versions. Over time, this can lead to a significant amount of disk
space being used for old versions of images that are no longer needed.

Because of this, you may wish to periodically run `docker image prune`
to delete any "dangling images" - images that aren't currently
associated with any image tags/names.

## Using Jupyter from Emacs

There are two primary ways you can work with Jupyter from Emacs:

### Driving a JupyterLab Console from Emacs

With [`jupyter-emacs`](https://github.com/nnicandro/emacs-jupyter),
you can use Emacs to run (Python or other) code in a browser-based
JupyterLab Console session that supports rich output (e.g. DataFrame
tables, plots, maps, etc.).

#### Installing

```
M-x package-refresh-contents <Enter>
M-x package-install <Enter>
jupyter
```

You may also like to add the following configuration to your
`init.el`:

```elisp
(require 'jupyter)

;; Don't display these buffers when output is added to them, since we
;; will be viewing rich output in the browser console session
(setq custom-jupyter-quiet-buffers '("*jupyter-display*" "*jupyter-output*" "*jupyter-traceback*"))
(when (not (boundp 'orig-jupyter-display-current-buffer-reuse-window))
 (setq orig-jupyter-display-current-buffer-reuse-window (symbol-function 'jupyter-display-current-buffer-reuse-window)))
(defun jupyter-display-current-buffer-reuse-window (&optional msg-type alist &rest actions)
  (when (not (member (buffer-name) custom-jupyter-quiet-buffers))
    (apply orig-jupyter-display-current-buffer-reuse-window msg-type alist actions)))

;; Add custom-jupyter-eval-sentence for evaluating contiguous blocks of code
(defun custom-jupyter-eval-sentence ()
  (interactive)
  (when-let* ((bounds (bounds-of-thing-at-point 'sentence)))
    (cl-destructuring-bind (beg . end) bounds
      (jupyter-eval-region beg end))))
(define-key jupyter-repl-interaction-mode-map (kbd "C-c C-c") #'custom-jupyter-eval-sentence)
```

#### Workflow

1. Ensure `make dev` is running
2. Open your notebook in JupyterLab
3. Right-click on the notebook's tab, and select `New Console for
   Notebook`
4. Right-click anywhere in the newly opened console, and ensure that
   `Show All Kernel Activity` is checked
5. In Emacs, run: `M-x jupyter-server-list-kernels` (URL:
   http://localhost:8888; use the token provided in the output of
   `make dev`)
6. In the `*jupyter-kernels*` buffer, select your running kernel
7. Open a file or buffer with code you want to execute in the console,
   and run `M-x jupyter-repl-associate-buffer`
8. Execute lines of code with:
   * `C-c C-b`: Execute the entire buffer
   * `C-x C-e`: Execute the current line or selected region
   * `C-c C-c`: Execute the current "sentence" (contiguous lines of code)
9. If you want to save some output in the notebook (e.g. a table or
   plot), add a notebook cell from JupyterLab to render that output.
10. You can even use JupyterLab's debugger to add breakpoints to
    previously run blocks of code, which will be triggered when
    re-running the same block.

### Running a Notebook

If you don't need rich outputs in your notebooks, you may prefer to
use [EIN](http://millejoh.github.io/emacs-ipython-notebook/) to
interact with notebooks solely from Emacs.

#### Installing EIN

```
M-x package-refresh-contents <Enter>
M-x package-install <Enter>
ein
```

#### Connecting EIN to your Jupyter server

1. Ensure `make dev` is running.
2. `M-x ein:login` (URL: http://127.0.0.1:8888, Password: token from `make dev`)
3. `M-x ein:notebooklist-open`

#### Common EIN Commands

```
M-<enter> - Execute cell and move to next.
C-c C-c - Execute cell.
C-c C-z - Interrupt command
C-c C-x C-r - Restart session
C-<up/down> - Navigate cells.
M-<up/down> - Move cells.
C-c C-b - Insert cell below (C-a for above).
C-c C-l - Clear cell output.
C-c C-k - Delete cell.
C-c C-f - Open file.
C-c C-h - Help at cursor.
C-c C-S-l - Clear all output.
C-c C-t - Toggle cell type.
```
