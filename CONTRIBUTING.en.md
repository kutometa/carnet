Thank you for your interest in contributing to this project. Please 
read this document carefully before you begin working on a feature 
you intend to contribute back to this repository.


# Table of Contents

1. Building
2. Testing
3. Contributing


# Building

Carnet is developed as a modular bash script, where the main script 
imports subscripts which in turn import their own subscripts and so 
on. 

You can assemble carnet by using `./etc/assemble.sh`. To assemble 
carnet for testing or redistribution, run the following command in 
the root of this repository:

```sh
bash ./etc/assemble.sh ./src/main.sh > ./carnet
chmod +x ./carnet
```


# Testing

Carnet is provided with a test suite that can be used to check for 
regressions. To run the test suite, you first build the script then 
run the following command in the root of this repository.

```sh
bash tests/carnet-test.sh
```

To run all tests (including ignored tests that can burden third-party
resources like crates.io), set the environment variable 
`TEST_IGNORED` to `yes`:

```sh
TEST_IGNORED=yes bash tests/carnet-test.sh
```


# Contributing

We classify contributions into one of two categories:

1. "Major" contributions where a substantial amount of code or other 
   copyrightable material is provided or modified.

2. "Minor" contributions that do not meet the threshold of 
   copyrightability. (e.g Typographical errors, One-line fixes, etc)

If you are not sure whether your contribution is major or minor, 
open an issue and ask.


### Major Contributions

To have a major contribution merged into this project, please follow 
these steps:

1. Before you start work on your contribution, open a new issue to
   see if your contribution is compatible with the goals and 
   constraints of this project. Otherwise, we might not be able to
   accept your contribution.
   
2. Fill and submit the Kutometa Contributor License Agreement if you 
   have not done so already. This agreement grants us a wider license
   to your contribution. This agreement does not assign your rights 
   to us.
   
3. Start implementing your contribution once you have determined that
   no technical or legal issue prevents us from accepting your 
   contribution.
   
4. Once finished, run the test suite and make sure all tests pass. 
   Running the _full_ test suite just before submitting a pull 
   request is highly recommended but not required at this time.

5. Update your issue and submit a patch or a pull request.
   

### Minor Contributions

Minor contributions are exempt from the steps required for major 
contributions. We still recommend running the test suite especially 
when code is modified.


