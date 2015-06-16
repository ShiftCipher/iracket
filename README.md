# IRacket

IRacket is a Racket kernel for IPython/Jupyter.

# Installation

## Requirements

* [Racket v6](http://racket-lang.org)
* These Racket packages installed (via `raco pkg install`):
    * [`git://github.com/greghendershott/sha#master`](https://github.com/greghendershott/sha#master)
    * [`git://github.com/tgiannak/racket-libuuid#osx-compat`](https://github.com/tgiannak/racket-libuuid#osx-compat)
    * [`git://github.com/tgiannak/racket-zeromq#wait-on-fd`](https://github.com/tgiannak/racket-zeromq#wait-on-fd)
* [ZeroMQ](http://zeromq.org)

## Installation steps

1. Clone this repository.
2. Run the following from the root of this repository
```bash
mkdir -p $(ipython locate)/kernels/racket/
cp ./static/kernel.json $(ipython locate)/kernels/racket/kernel.json
```
3. Adjust the copied `kernel.json` to refer to iracket in the path of this
   repository.
4. If `racket` isn't on your path, adjust the copied `kernel.json` to refer to
   the absolute path of `racket`.

### C3 Integration (Charts)

_Note that the front-end integration for C3 will eventually be moved into its
own repository._

If you use a non-default profile, set `IPYTHON_PROFILE` to the name of that
profile, then run the following:

```bash
IPYTHON_PROFILE=
cp static/ic3.js $(ipython locate)/nbextension/ic3.js
cat static/custom.js >> $(ipython locate profile IPYTHON_PROFILE)/custom/custom.js
curl -L https://github.com/mbostock/d3/raw/v3.5.5/d3.min.js > $(ipython locate profile IPYTHON_PROFILE)/static/d3.js
curl -L https://github.com/masayuki0812/c3/raw/0.4.10/c3.min.js > $(ipython locate profile IPYTHON_PROFILE)/static/c3.js
curl -L https://github.com/masayuki0812/c3/raw/0.4.10/c3.min.css > $(ipython locate profile IPYTHON_PROFILE)/static/c3.css
```

This script will
* copy the nbextension for C3 into your IPython nbextension folder,
* append the code for loading the extension to your IPython profile's
  custom.js, and
* add the required D3 and C3 code to your IPython profile's static resources
  folder.

To display C3 charts, evaluate a `cons` cell whose `car` is the symbol
`'c3-data` and whose `cdr` is a `jsexpr` (from the `json` package) of the data
structure to pass to C3's `generate` function.

Example
```racket
(cons 'c3-data
      (hasheq 'data
              (hasheq 'columns
                      (list (list "data1" 30 200 100 400 150 250)
                            (list "data2" 50 20 10 40 15 25)))))
```


# Using the kernel

Run the ipython notebook server as you usually do, e.g.
```bash
ipython notebook
```
and create a new notebook with the Racket kernel.
