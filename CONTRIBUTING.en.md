Thank you for your interest in contributing to our project. Please 
read this document carefully before you start working on a feature 
that you intend to contribute back to this repository.


# Table of Contents

1. Building
2. Testing
3. Contributing


# Building

Carnet is developed as a set of partial bash files that require 
assembly into a single executable file before Carnet can be used 
normally. 

You can assemble carnet by using `./etc/assemble.sh`. To assemble 
carnet for testing or redistribution, run the following command in 
the root of this repository:

```sh
bash ./etc/assemble.sh ./src/main.sh > ./carnet
chmod +x ./carnet
```


# Testing

Carnet is bundled with a test suite that can be used to check for 
regressions and other issues. To run the test suite, you first build 
the script then run the following command in the root of this 
repository.

```sh
bash tests/carnet-test.sh
```

To run all tests, including those ignored by default, set the 
environment variable `TEST_IGNORED` to `yes`:

```sh
TEST_IGNORED=yes bash tests/carnet-test.sh
```


# Contributing

We classify contributions into one of the following two categories:

1. **Major** contributions where a substantial amount of code or other 
   copyrightable material is provided or modified.

2. **Minor** contributions that do not meet the threshold of 
   copyrightability. (e.g Typographical errors, One-line fixes, etc)

If you are not sure whether your contribution will be treated as 
major or minor, please open an issue and ask.


### Major Contributions

To have a major contribution merged into this project, please follow 
these steps:

1. Before you start working on your contribution, open a new issue to 
   determine if your contribution is compatible with this project's 
   goals and constraints.
   
2. Fill and submit the Kutometa Contributor License Agreement form if
   you haven't done so already. This agreement grants us the ability 
   to license your contribution for commercial use and to address 
   legal issues as they arise. This agreement does not assign your 
   copyright to us.
   
3. Start implementing your contribution.
   
4. (Optional) add tests to the test suite.

5. Run the test suite and make sure all tests pass. 
 
6. (Optional) Run the _full_ test suite and make sure all tests pass. 
   
7. Update your issue and submit a patch or a pull request.
   

### Minor Contributions

Minor contributions are exempt from the steps required for major 
contributions. We still recommend running the test suite especially 
when code is modified.

# Questions

Open a new issue!
