# Fundamentals of Ansible: Learn the essentials of configuration as code

## Highlights

- This **is a workshop**. Please come with a laptop that has the necessary installed software.
- Please follow **all of the installation instructions** in this document before coming to the workshop.
  Debugging Docker/Git installation takes time away from all attendees.

## Installation

You will need the following installed

- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible)
- [Docker](https://www.docker.com/get-started/)
- [Git](https://git-scm.com/downloads)
- Clone this repository
- A good text editor.
  I highly recommend [VS Code](https://code.visualstudio.com/).


### Set up

- `docker build -t cac-with-ansible:1.0.0 .`

### Testing your installation

Let's create a docker network so our containers can discover each other over DNS.
- `docker network create cac`

Next, we start our two target servers, making sure we expose the necessary ports, and that they are part of docker network we just created.

- `docker container run --name app -d -t -p 9000:8080 --network cac cac-with-ansible:1.0.0`
- `docker container run --name web -d -t -p 8080:80 --network cac cac-with-ansible:1.0.0`

Let's make sure they are up
- `docker container ls`

This should reveal the two containers running, with the names `app` and `web`.

### Publishing Java application

If you wish to build the Java application, you'll need Java 21 installed and available.
You'll also need a GitHub "publish" token

```
export TOKEN="<GITHUB_TOKEN>"
./gradlew publish
open https://github.com/looselytyped?tab=packages&repo_name=cac-with-ansible
```
