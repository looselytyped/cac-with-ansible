autoscale: true
theme: Plain Jane, 2
slidenumbers: true
# Fundamentals of Ansible: Learn the essentials of configuration as code

---
## What you'll need

- Clone the repository at [https://github.com/looselytyped/cac-with-ansible](https://github.com/looselytyped/cac-with-ansible)
- Follow the instructions in the [README.md](https://github.com/looselytyped/cac-with-ansible/blob/master/README.md)

---
## Ansible?

---
## Discussion: Why Ansible?

- Cattle, Not Pets
- Consistency across machines/environments
- Automate everything
- Better collaboration between Dev and Ops
- SDLC for configuration management

---
## Discussion: How does Ansible work?

- Ansible runs from a "control box" (in our workshop that will be our workstations)
- It connects to the nodes using SSH (in or case that's going to be docker containers)
- It then pushes out code (modules) to these nodes and executes them on those nodes

```
       ┌────────┐     ┌────────┐     ┌────────┐
       │ Node 1 │     │ Node 2 │     │ Node 3 │
       └────────┘     └────────┘     └────────┘
            ▲              ▲              ▲
            │              │              │
            │              │              │
            │      ┌───────┴───────┐      │
            └──────┤  Control Box  ├──────┘
                   └───────────────┘
```

---
## Discussion: Ansible characteristics

- Push
- Declarative
- SSH
- Agentless

---
## Discussion: Setup (See hints at the bottom if something goes wrong)

```bash
# if you have NOT built the base image
# run this at the root of my project
docker build -t cac-with-ansible:1.0.0 docker-setup

# start our containers
docker network create cac
docker container run --rm --name web -d -t -p 8080:80 --network cac cac-with-ansible:1.0.0
docker container run --rm --name app -d -t -p 9000:8080 --network cac cac-with-ansible:1.0.0
```

---
## Let's get started!

Why docker?
This repository contains a Vagrantfile that creates VMs that you can configure with Ansible.
However, when learning, you want a safety net, and one that you can recover from quickly.
While VMs give you a more "real" sense of how you'd use Ansible at work, containers (which aren't really VMs) give you a mechanism to recover quickly if something goes wrong.
In other words, stopping, deleting and restarting a container is _way_ faster than a VM.

Not to mention, networking containers on a single host is a lot easier :)

---
## Discussion: Run ansible for the first time

```bash
ansible all --inventory web, --connection=docker --module-name ansible.builtin.ping
# using short aliases
ansible all -i web, --connection=docker -m ansible.builtin.ping
```

---
## Exercise: Run ansible for the first time

- [ ] Use ansible to ping to the "app" container
  - Feel free to use `docker container ls` to see your inventory of servers
- [ ] **Extra credit**: Can you figure out how to `ping` both the `web` and `app` containers?

---
## Discussion: Run an ansible module with args

Ansible's core functionality is packaged in "modules".
`ping` is one such module which simply returns `pong` on successful contact.

Modules can also take arguments, supplied with the `--arg`.

```bash
ansible all -i web, --connection=docker -m ansible.builtin.ping --arg 'data=hello'
# using short aliases
ansible all -i web, --connection=docker -m ansible.builtin.ping -a 'data=hello'
```

---
## Exercise: Run an ansible module with args

- [ ] Ansible has a [`ansible.builtin.command`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/command_module.html) that takes the command you wish to run as it's argument.
      Can you figure out how to run the `uptime` command against the `web` container?
- [ ] How about against both `web` and `app` containers at the same time?

---
## Discussion: Escalating privileges

Every so often you need to have escalated privileges to do some tasks.
You can "become" another user (like `root`) if the server allows you to do that.

```bash
# this will fail b/c the default user in the container in "vagrant", and
# does not have privileges to read the sudoers file
ansible all -i web, --connection=docker -m ansible.builtin.command -a "cat /etc/sudoers"
# you can "become" which, by default, attempts to make the current user "root" using "sudo"
ansible all -i web, --connection=docker --become -m ansible.builtin.command -a "cat /etc/sudoers"
# using short aliases
ansible all -i web, --connection=docker -b -m ansible.builtin.command -a "cat /etc/sudoers"
```

---
## Exercise: Escalating privileges

Ansible supports the `--become-method` to control which escalation method to use to escalate privileges.

- [ ] Use `ansible --help` to see the documentation for `--become_method`
- [ ] Use `ansible-doc -t become -l` to see what your choices are
- [ ] Provide both `become` and `become-method` to `cat /etc/sudoers` in the `app` container

**Woot!** You are now expanding your repertoire of Ansible tools!
You just used `ansible-doc`—we'll be seeing more as we continue through today's workshop.

---
## Discussion: Keeping track of your inventory

Ansible aims to make things easier.
Managing your inventory in one such thing.
Rather than having to remember the names and/or IP addresses of your servers, you can declare an "inventory" for Ansible to use, and then target specific servers listed in that inventory.

An Ansible inventory is typically written in a (slightly convoluted) INI format.
It is comprised of "groups" of servers, like so:

```ini
# the name within square brackets is the name of the group
[frontend]
# underneath the name of the group you list the servers that are part of this group
# this list can be as long as you like it to be, and can have DNS names, or IP addresses
web
```

**Note**: We will put our inventory file (named `inventory`) in a folder called `environments/development`.

---

In order to use this with the `ansible` command, you use the `--inventory` flag along with the server you wish to target.
Ansible, by default, _looks_ for a file with the name `inventory`—if you name it something else, then you have to specify the name of the file explicitly.

**This is your first introduction to Ansible's "convention over configuration" mantra!**

```bash
# specify inventory file and pick a specific server
ansible --inventory environments/development --connection=docker web -b -m command -a "cat /etc/sudoers"
# using short aliases
ansible -i environments/development --connection=docker web -b -m command -a "cat /etc/sudoers"
```

You can even target a whole group of servers:

```bash
# if there were more than one server in the "frontend" group, Ansible would connect to all of them
ansible -i environments/development --connection=docker frontend -m ping
```

---
## Exercise: Keeping track of your inventory

- [ ] Create a file called `inventory` under `environments/development`
- [ ] Populate it with a "group" called `frontend` with one entry `web`
- [ ] Populate it with a group called `backend` with one entry `app`

  ```bash
  docker container run --rm --name web1 -d -t --network cac cac-with-ansible:1.0.0
  ansible -i environments/development --connection=docker frontend -m ping
  ansible -i environments/development --connection=docker backend -m ping
  ```
- [ ] **Extra credit**: Start a _third_ container with a specific nasme (e.g. `web1`), add it to the inventory, and then use Ansible to `ping` all the servers in the `frontend` group. Here are the terminal commands you'll need:

  ```bash
  docker container run --rm --name web1 -d -t --network cac cac-with-ansible:1.0.0
  ansible -i environments/development --connection=docker frontend -m ping
  ```

---
## Discussion: Groups of groups (of groups?)

Ansible allows you to "group" groups, creating interesting ways to slide and dice your inventory.

```ini
[us_east]
host1
host2

[us_west]
host3

[uk_east]
host5

[uk_west]
host7

[usa:children]
us_east
us_west

[uk:children]
uk_east
uk_west

[infra:children]
usa
uk
```

---
Inventory files can get rather expansive.
To see what your inventory graph looks like, you can ask Ansible

```bash
ansible-inventory -i environments/development --graph
```

**Note** You just added another Ansible utility to your toolbelt.
So far you've used `ansible`, `ansible-doc` and `ansible-inventory`.

---
## Exercise: Groups of groups (of groups?)

- [ ] Temporarily **add** the groups (`us_east`, `us_west` etc) shown above to your `environments/development` file
- [ ] See what Ansible lists with the following for different group names

  ```bash
  ansible -i environments/development --connection=docker <group-name> --list-hosts
  ```
- [ ] **Remove the newly entered (`us_east`, `us_west` etc) groups**

---
## Discussion: Variables, specifically inventory variables

You are probably getting tired of typing `--connection=docker` every time you run ansible.

Turns out, Ansible has many mechanisms to declare variables.
One place you can declare variables is in the inventory file, either ones that specifically apply to specific servers, groups or _all_ servers in that inventory.

```ini
# rest of the file truncated for brevity
[all:vars]
ansible_connection=docker
```

---

You can now skip having to supply it at the command-line every time:

```bash
ansible -i environments/development all -m ping
# or
ansible -i environments/development frontend -m ping
# or
ansible -i environments/development app -m ping
```

Turns out, you can declare "host" or "group" level variables as well.

```ini
[frontend]
# this is a host level variable
web username=raju

[backend]
app

[infra:children]
frontend
backend

# this is a group level variable
[backend:vars]
foo=bar
```
---
And you can ask Ansible to print out their values using the `debug` module

```bash
# see what the value of the `username` variable is for the "web" HOST
ansible -i environments/development web -m ansible.builtin.debug -a var=username
# see what the value of the `foo` variable for the "backend" GROUP
ansible -i environments/development backend -m ansible.builtin.debug -a var=foo
```

**Note the use of the words group vars or host vars—we'll revisit this soon**

---
## Exercise: Variables, specifically inventory variables

- [ ] Introduce the variable you need to configure your connection type in your inventory file
  - [ ] See if `ansible -i environments/development all -m ping` works for you
- [ ] Introduce some made up host and group variables like you see above
  - [ ] Use `ansible-doc ansible.builtin.debug` or read over the [`ansible.builtin.debug`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html#ansible-collections-ansible-builtin-debug-module) documentation to figure out how to use `ansible.builtin.debug` to display a `var` value
  - [ ] Use the `ansible.builtin.debug` to check if the values of the variables you declared are showing up correctly
  - **NOTE** Be sure to use the _correct_ host/group
  - [ ] **Extra credit**: What happens if you ask for the value of a variable that does not exist?

---
## Discussion: Extracting group and host variables into group/host variable files

While you _can_ use the inventory file to store your variables, it gets harder when you have large inventories, and you have a lot of variables.
Furthermore, **you can only have strings and booleans in the inventory file.**
It's usually better to extract those variables into separate files.

Typically, you house all _group vars_ in a directory called `group_vars` and (no surprise) all _host vars_ in a directory called `host_vars`, in the same directory as the `inventory` file.
Within those folders, you put file names that align with the names of the groups or hosts, like so:

```bash
# Remember, `all` is a valid group!
environments/development
├── group_vars
│  ├── all
│  ├── backend
│  └── frontend
├── host_vars
│  └── web
└── inventory
```

---

Couple of notes:
- The files inside the `group_vars` and `host_vars` are YAML files (but you can skip the extension)
  Here's an example of what `host_vars/app` looks like (Note: In inventory file you use `=`, here you use`:`)

  ```yaml
  # development/host_vars/web
  username: raju

  # development/group_vars/backend
  foo: bar
  ```
- You only need the files for groups/hosts that you have variables for.

Our previous demonstration works just as it did before:

```bash
# see what the value of the `username` variable is for the "app" HOST
ansible -i environments/development web -m ansible.builtin.debug -a var=username
# see what the value of the `foo` variable for the "backend" GROUP
ansible -i environments/development backend -m ansible.builtin.debug -a var=foo
```

---
## Exercise: Extracting group and host variables into group/host variable files
- [ ] Create all the files you need to extract the variables you introduced in the last exercise (Be sure to create `group_vars/all` for sure!)
- [ ] Refactor your inventory files to clean it up and put your variables in the correct group/host file
  - [ ] Use the `ansible.builtin.debug` to check if the values of the variables you declared are showing up correctly
  **NOTE** Be sure to use the _correct_ host/group
- [ ] **Extra credit**: What happens if you declare the same variable for a group and a host in that group that happens to have different values?
  Which one wins?

---
## Discussion: Plays and playbooks

Running commands on the command-line will only take you so far.
Usually you want to run a sequence of tasks in a particular order, which is where "plays" come into the picture.

A play is a YAML file, that connects a set of hosts (`all`, groups or hosts) to a list of tasks.

A playbook, on the other hand, consists of multiple plays.

```
# Using https://asciiflow.com/#/

 ┌──────────────┐1     n┌──────────────┐1    n┌──────────────┐
 │   Playbook   ├──────<│    Play      ├─────<│    Hosts     │
 └──────────────┘       └──────┬───────┘      └──────────────┘
                              1│
                              n^
                        ┌──────────────┐1    1┌──────────────┐
                        │    Task      ├─────►│    Module    │
                        └──────────────┘      └──────────────┘
```

---
## Discussion: Let's write our first play

Let's convert `ansible -i environments/development backend -m ansible.builtin.debug -a var=foo` to a play.
Things to note:
- We are targeting the `backend` group
- We are invoking the `ansible.builtin.debug` module
- We are supplying it the argument `var=foo`

Here's the play

```yaml
# test-playbook.yaml
- name: Install nginx
  hosts: frontend
  # a play connects a set of hosts, to a list of tasks
  tasks:
  - name: Print the value of a variable
    ansible.builtin.debug:
      var: username
```

---
## Exercise: Let's write our first play

- [ ] Create a file called `test-playbook.yaml` in your root directory
- Create a play with the following details:
  - [ ] Give it the `name` `Install nginx`
  - [ ] Target the `frontend` group
    - **Write two tasks** (Be sure to give them good names!)
      - [ ] The first one should print the value of one of your variables using `ansible.builtin.debug`
      - [ ] The second should use `ansible.builtin.ping`, with some `data` (Use the [docs](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html) to see how to use it in a play)
- [ ] Use `ansible-playbook -v -i environments/development/ test-playbook.yaml` run your playbook (**Note** the use of `-v` in there)

---
## Discussion: Environment specific variables

We did something sneakily.
Note that you could see the variables you declared in the `group_vars` and `host_vars` in the playbook.
This happens because you told Ansible _which_ inventory to use—e.g. `environments/development/`.

But you could have ANOTHER directory, say `environments/localhost` or `environments/production` with the same variables with _different_ values.

Depending on _which_ inventory you supply Ansible, you can configure different "environments" _differently_.

```
                                                                  ┌─────────────────────┐
                                                                  │                     │
                                                                  │   development/      │
                                                                  │   |-- group_vars    │
                                                                  │   |   |-- all       │
                                                                  │   |   |-- backend   │
                                                                  │   |   `-- frontend  │
                                                                  │   |-- host_vars     │
                                                                  │   |   `-- web       │
                                                                  │   `-- inventory     │
                                                                  │                     │
                                                                  └─────────────────────┘
                                                                             ▲
 ┌──────────────┐     ┌──────────────┐      ┌──────────────┐                 │
 │   Playbook   ├────►│    Play      ├─────►│    Hosts     ├─────────────────┤
 └──────────────┘     └──────┬───────┘      └──────────────┘                 │
                             │                                               ▼
                             ▼                                    ┌─────────────────────┐
                      ┌──────────────┐      ┌──────────────┐      │                     │
                      │    Tasks     ├─────►│   Modules    │      │   localhost/        │
                      └──────────────┘      └──────────────┘      │   |-- group_vars    │
                                                                  │   |   |-- all       │
                                                                  │   |   |-- backend   │
                                                                  │   |   `-- frontend  │
                                                                  │   |-- host_vars     │
                                                                  │   |   `-- web       │
                                                                  │   `-- inventory     │
                                                                  │                     │
                                                                  └─────────────────────┘
```

---
## Exercise: Environment specific variables

- [ ] Create the `environments/localhost` directory with all the required files
  **It might be easier just to duplicate the `development` folder (in bash, `cp -r environments/development environments/localhost` should do it)
- [ ] Change the value of some of the variables
- [ ] Make sure your playbook prints those values
- [ ] Run both `ansible-playbook -v -i environments/development/ test-playbook.yaml` and `ansible-playbook -v -i environments/localhost/ test-playbook.yaml` and make sure you see the correct values for both.

---
## Discussion: Let's make a useful playbook

Recall that a _playbook_ is a collection of plays.
Here's what a playbook, consisting of two plays looks like:

```yaml
# a playbook is a _list_ of plays
# this is the first play, targeting the `frontend` servers
- name: Install nginx
  hosts: frontend
  tasks:
  - name: Print the value of a variable
    ansible.builtin.debug:
      var: username
  - name: Ping the server
    ansible.builtin.ping:
      data: pong


- name: Install Java
  hosts: backend
  tasks:
    - name: Install Java 21
      ansible.builtin.apt:
        name: openjdk-21-jdk=21.0.5+11-1ubuntu1~22.04
        state: present
        update_cache: yes
      # Remember the `--become` (or `-b`) flag you passed on the command-line earlier?
      # This is the playbook equivalent of that.
      become: true
```

---
## Exercise: Let's make a useful playbook

- In `test-playbook.yaml`
  - [ ] For the `Install Nginx` play, add a new task that installs `nginx` (version `1.18.0-6ubuntu14.5`) in the `frontend` hosts (See above for hints)
    - **Note** You will need to _become_ superuser
  - [ ] Add a **second play**
    - [ ] Give it the `name` `Install Java`
    - [ ] Target the `backend` group
      - **Write one task** (Be sure to give it a good name!)
        - [ ] Install `openjdk-21-jdk` (version `21.0.5+11-1ubuntu1~22.04`) (See above for hints)
- [ ] Use `ansible-playbook -i environments/development/ test-playbook.yaml` run your playbook
- Execute the following to make sure you got everything installed correctly:

  ```bash
  docker exec web nginx -v
  docker exec app java -version
  ```
- [ ] **Extra credit**: Is it a good idea to hard code the version numbers in the playbook?
  Think about the two different inventories you have in your `environments`.
  Announce your answer in chat or send it to me privately.

---
## Discussion: Jinja2 string interpolation

Ansible supports Jinja2, which is a fast, expressive, extensible templating engine.
You might be uncomfortable hard-coding the version numbers, given that you do have multiple inventories.
It's not unusual to upgrade a lower tier to let a new version soak in, and then "promote" that version to higher environments.

If you wish to use a variable in a string, Jinja2 uses double curly braces.
Here's an example:

```yaml
- name: Print the value of a variable
  ansible.builtin.debug:
    # We are using the 'msg' which prints a message (in this case using interpolation)
    # as opposed to var which can only take the name of a variable
    msg: "The user is {{ username }}"
```

**Note** that you don't need to put white-space within the curly brackets.
`{{ username }}` is the same as `{{username}}` which is the same as `{{username }}` or `{{ username}}`.

---
## Exercise: Jinja2 string interpolation

- [ ] Extract the version numbers of `nginx` and `openjdk` to your `group_vars`
  - You can use variable names like `nginx_version` and `java_version` or something to that effect
  - **Be sure to put them in both the inventories (`development` and `localhost`)**
- [ ] Use them in your playbook using Jinja2 interpolation
- [ ] Use `ansible-playbook -i environments/development/ test-playbook.yaml` run your playbook

---
## Discussion: A bit of refactoring

Our playbook, while simple, combines two different concerns.
Let's split them into multiple playbooks so it's clear what they do, and it will help with our future refactoring.

```bash
.
├── backend-setup.yaml # introduce this
├── environments
├── frontend-setup.yaml # introduce this
├── Notes.md
├── README.md
└── test-playbook.yaml
```

---
## Exercise: A bit of refactoring

- [ ] Create two new files, `backend-setup.yaml` (that uses the `name` `Install Java` for the playbook) and `frontend-setup.yaml` (with `name` `Install nginx`)
- [ ] Pull out the appropriate code from `test-playbook.yaml`
- [ ] Be sure to run `ansible-playbook -i environments/development/ backend-setup.yaml` and `ansible-playbook -i environments/development/ frontend-setup.yaml` to ensure all is well
- **Note** you can run multiple playbooks at the same time: `ansible-playbook -i environments/development/ backend-setup.yaml frontend-setup.yaml`
- Do not delete `test-playbook.yaml`.
  Keep it around to run experiments.

---
## Discussion: Introducing roles

Playbooks can get long and complex.
Roles offer a way to "package" everything you need to perform a specific kind of work together, for better reuse, and even sharing with others.

By convention roles are stored in a directory called `roles`.

```
.
├── ansible.cfg
├── backend-setup.yaml
├── frontend-setup.yaml
├── Notes.md
├── README.md
└── roles # there it is!
```

---

An Ansible role is a highly structured directory structure, which again, uses Ansible's convention-over-configuration approach.
Here's an example:

```
roles/nginx-configure
├── defaults
│  └── main.yaml
├── files
├── handlers
│  └── main.yaml
├── meta
│  ├── container.yaml
│  └── main.yaml
├── README.md
├── tasks
│  └── main.yaml  # this is where all your tasks reside
├── templates
│  └── etc
├── tests
│  ├── ansible.cfg
│  ├── inventory
│  └── test.yaml
└── vars
   └── main.yaml
```

To use a role in a playbook, you use the `role` keyword, like so:

```yaml
- name: Install nginx
  hosts: frontend
  # this makes every task in every role run as superuser
  become: true
  # there it is—you supply it a list of roles to invoke, in order
  roles:
    - nginx-configure
```

---
## Exercise: Introducing roles

- [ ] Split `test-playbook.yaml` into `frontend-setup.yaml` and `backend-setup.yaml`
- [ ] Ansible has a `ansible-galaxy` command that let's you quickly generate all the files you need for a role.
  Use `ansible-galaxy role init roles/nginx-configure` to generate the `nginx-configure` role
- [ ] Move the tasks you declared in `Install Nginx` playbook into the `roles/nginx-configure/tasks/main.yml` file
- [ ] Use the `roles` key to have `frontend-setup.yaml` use the `nginx-configure` role
- [ ] **Repeat** the steps above to create and populate a `app-configure` role
- [ ] Move the tasks you declared in `Install Java` playbook into the `roles/app-configure/tasks/main.yml` file
- [ ] Be sure to run `ansible-playbook -i environments/development/ backend-setup.yaml frontend-setup.yaml` to ensure all is well

---
## Discussion: Using ansible.builtin.copy in roles

Every so often you'd like to copy a file that you manage in Ansible to the target server.
Typically, the files you put here are binaries, or files that you wish to copy as-is.

To copy files, Ansible supports `ansible.builtin.copy` module.
The advantage of using roles is that Ansible will automatically look in the `files` folder for any files that you wish to copy over to the target.

```yaml
# roles/nginx-configure/tasks
- name: Copy a file to the home directory
  copy:
    # some-file.txt should be in roles/nginx-configure/files
    src: some-file.txt
    dest: ~/
```

---
## Exercise: Using `ansible.builtin.copy` in roles

- [ ] Create a file called `sample-key.pub` in `roles/nginx-configure/files` with the following content:
  ```
  ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSU
  GPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3
  Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XA
  t3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/En
  mZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbx
  NrRFi9wrf+M7Q== cac-with-ansible@controlbox.mycompany.com
  ```
- Use the [`ansible.builtin.file`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html#ansible-collections-ansible-builtin-file-module) module (See examples at the end of that page) to
  - [ ] Create the `~/.ssh` directory
  - [ ] With the permissions (`mode`) `'0700'`
- Then use [`ansible.builtin.copy`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
  - [ ] to copy the newly created `sample-key.pub` file to the root users `~/.ssh` directory
  - [ ] With permissions `'0644'`
- [ ] Run `ansible-playbook -i environments/development/ frontend-setup.yaml` to run your playbook
- [ ] Use `docker exec --user root web ls -alh /root/.ssh` to make sure that directory really got created
- [ ] Use `docker exec --user root web cat /root/.ssh/sample-key.pub` to make sure that your file has the contents you expect them to have
- [ ] Run `ansible-playbook -i environments/development/ frontend-setup.yaml` again and notice the `changed` count

---
## Discussion: Using ansible.builtin.template in roles

`ansible.builtin.file` is useful when copying files as is.
Every so often you want to _templatize_ the contents of files.
This is where the `ansible.builtin.template` comes in, along with the `templates` folder that is part of the default role directory structure.

Let's say you have a variable `port: 8080` and you have a template that looks like this (Notice we use Jinja2 templating here):

```jinja
<!-- roles/nginx-configure/templates/test.conf.j2 -->
upstream backend {
  server app:{{ port }};
}
```

You can then use `ansible.builtin.template` to first interpolate all the variables in the template, and _then_ copy them over to the target server.

```yaml
- name: Interpolate variables and then copy over file
  ansible.builtin.template:
    # test.j2 should be in roles/nginx-configure/templates
    # notice the j2 extension
    src: "test.conf.j2"
    # note that by default the name will have `j2` in it
    # if you don't explicitly state the name
    dest: /root/test.conf
```

---
## Exercise: Using `ansible.builtin.template` in roles

- [ ] Create a variable `port: 8080` in `environments/development/group_vars/frontend`
- [ ] Create a file at `roles/nginx-configure/templates/etc/nginx/conf.d/app.conf.j2` with the following location (Notice the templatized variable):

  ```jinja
  events {
    worker_connections  4096;  ## Default: 1024
  }

  http {
    server {

      access_log /var/log/nginx/access.log;
      error_log /var/log/nginx/error.log;

      location / {
        proxy_pass http://backend;
      }
    }


    upstream backend {
      server app:{{ port }};
    }
  }
  ```
- Use the [`ansible.builtin.template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html#ansible-collections-ansible-builtin-template-module) module
  - [ ] to copy the `etc/nginx/conf.d/app.conf.j2` file to `/etc/nginx/nginx.conf`
- [ ] Run `ansible-playbook -i environments/development/ frontend-setup.yaml` to apply your changes
- [ ] Use `docker exec --user root web cat /etc/nginx/nginx.conf` to ensure that the file showed up correctly in nginx configuration directory
- [ ] Use `docker exec --user root web nginx -t` to have nginx check your configuration

---
## Discussion: Using handlers

Every so often, you wish to run a task when something _changes_.
For example, if the `nginx.conf` file were to change, the nginx needs to be restarted.

For this, Ansible roles offer "handlers".
A handler is a task, but can be "notified" from another task.
Couple of notes:
- Multiple tasks can notify the same handler
- Handlers (unless specifically told to) only run at **after** all the tasks (in `tasks/main.yml`) have run
  - Consequently, handlers only run once, even if they are notified multiple times
- You can have multiple handlers in a role
  If you notify multiple handlers within your tasks, then they will run in the order they are defined in `handlers/main.yml` (not in the order that they were notified)
- **Note** Handlers are only called when a task _changed_.

---

```yaml
# in roles/nginx-configure/handlers/main.yaml
- name: reload nginx
  ansible.builtin.debug:
    msg: Handler was called
```
In your `template` task, you can now notify the event by it's name:

```yaml
- name: Deploy standard nginx.conf
  ansible.builtin.template:
    src: "etc/nginx/app.conf.j2"
    dest: /etc/nginx/nginx.conf
  # here's the notification. Notice it's a list
  notify:
    - reload nginx
```

---
## Exercise: Using handlers

- Define a handler named `reload nginx` that uses [`ansible.builtin.systemd_service`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/systemd_service_module.html) in `roles/nginx-configure/handlers/main.yml`
  - [ ] work with the unit `name`-ed `nginx`
  - [ ] ensure the `state` is `reloaded`
  - [ ] be sure to `daemon_reload` systemd
  - [ ] and make sure it's `enabled`
- [ ] `notify` `reload nginx` in the task in `tasks/main.yaml` that copies over the nginx conf file
- [ ] **IMPORTANT** Put an extra newline in `roles/nginx-configure/templates/etc/nginx/conf.d/app.conf.j2` so Ansible is forced to re-copy that file over
- [ ] Run `ansible-playbook -i environments/development/ frontend-setup.yaml` to apply your changes
  - Make sure you see `RUNNING HANDLER` in the Ansible output
- [ ] Run `ansible-playbook -i environments/development/ frontend-setup.yaml` to apply your changes *again* and notice that the handler **does not get invoked**

---
## Discussion: Another place to declare variables

We are done with the nginx role.
However, before we move on, let's talk about managing secrets.
You certainly **don't want** to put these in Ansible, especially in plain-text.

You can use a variable in your Ansible scripts, without declaring it.

```yaml
# in backend-setup.yaml
- name: Install Java
  hosts: backend
  tasks:
  - name: Print the value of a variable
    ansible.builtin.debug:
      var: GITHUB_TOKEN
```

You can then supply it at the command-line using the `--extra-vars` flag, like so:

```bash
ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' backend-setup.yaml
# using short aliases
ansible-playbook -i environments/development/ -e GITHUB_TOKEN='password' backend-setup.yaml
```

---
## Exercise: Another place to declare variables

- [ ] Use the code above in backend-setup.yaml
- [ ] Run `ansible-playbook -i environments/development/ -e GITHUB_TOKEN='password' backend-setup.yaml` to make sure that you see the correct output
  - **I will provide you the value for `password` when we start the workshop**

---
## Discussion: Let's introduce the backend role

We are going to create another role that offers a few other interesting challenges.
We'll start by creating the role and then refactor it using some nifty Ansible capabilities.
We've already created the `app-configure` role and we are using it in `backend-setup.yaml`

```yaml
# roles/app-configure/tasks/main.yml
- name: Install wget
  ansible.builtin.apt:
    name: wget=1.21.2-2ubuntu1.1
    state: present
    update_cache: yes
  become: true

# we don't need curl, but we will install it
# for didactic perspectives
- name: Install curl
  ansible.builtin.apt:
    name: curl=7.81.0-1ubuntu1.19
    state: present
    update_cache: yes
  become: true

# from https://docs.aws.amazon.com/corretto/latest/corretto-21-ug/generic-linux-install.html#debian-install-instruct
- name: Set up repositories
  ansible.builtin.shell: >
    wget -O - https://apt.corretto.aws/corretto.key
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/corretto-keyring.gpg
    && echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main"
    | sudo tee /etc/apt/sources.list.d/corretto.list

- name: Install java
  ansible.builtin.apt:
    name: java-22-amazon-corretto-jdk
    state: present
    update_cache: yes
  become: true

- name: Create app directory if it does not exist
  file:
    path: "{{ install_dir }}"
    state: directory
    owner: vagrant
    group: vagrant

- name: Install lxml via pip
  ansible.builtin.pip:
    name=lxml==5.2.2

- name: Fetch the jar
  community.general.maven_artifact:
    group_id: "com.looselytyped"
    artifact_id: "cac-with-ansible-backend"
    version: "0.0.1-SNAPSHOT"
    extension: jar
    repository_url: "https://maven.pkg.github.com/looselytyped/cac-with-ansible"
    username: 'looselytyped'
    password: "{{ GITHUB_TOKEN }}"
    dest: "{{ install_dir }}/cac-with-ansible-backend.jar"
    mode: 0644
    verify_checksum: always

- name: Create systemd service file
  template:
    src: "etc/systemd/system/app.service.j2"
    dest: "/etc/systemd/system/app.service"
    mode: 0644
  notify:
    - restart application
  # TODO: REMOVE THIS
  changed_when: true
  become: true
```
---
```yaml
# roles/app-configure/handlers/main.yml
- name: restart application
  ansible.builtin.systemd_service:
    name: app
    state: restarted
    daemon_reload: yes
    enabled: yes
  become: true
```
```ini
# roles/app-configure/templates/etc/systemd/system/app.service.j2
[Unit]
Description=My Java app
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/vagrant/app
ExecStart=/usr/bin/java \
  -Xms499m \
  -Xmx999m \
  -jar cac-with-ansible-backend.jar
TimeoutSec=15
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

```yaml
# roles/app-configure/defaults/main.yml
install_dir: /home/vagrant/app
```

---
## Exercise: Let's introduce the backend role

- [ ] Use the snippets above to finish your `app-configure` role.
  **Pay close attention to the file paths—be sure to put the right content in the right file!**
- [ ] Use `ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' backend-setup.yaml` where you replace `password` with the token I give you
- [ ] Visit http://localhost:8080/greeting?name=ansible and make sure you see the message `Hello ansible` (Change the `name` param to anything you like)

---
## Discussion: Using Ansible facts and filters

Every so often so you want to use characteristics of the host—maybe you need to know the IP address of the host, the operating system or how much memory is available to you.
If you look carefully at the output of `ansible-playbook` you will see the following:

```
TASK [Gathering Facts] ************************************************************************************
Thursday 04 July 2024  13:36:23 -0400 (0:00:00.012)       0:00:00.012 *********
ok: [app]
```

These "facts" are available to you, and you can use them in your playbooks/plays/roles.

```bash
# list all facts for a particular group/host
ansible app -m setup -i environments/development
```

You can use them like so:

```yaml
- name: Use Ansible facts/filters
  debug:
    # notice the use of math operation, and the `type_debug` filter
    # and that the value is of type `float`
    msg: "The total real memory available is {{ (ansible_memory_mb.real.total/32) | type_debug }}"
```

---
## Exercise: Using Ansible facts and filters

- [ ] Use the `int` filter in `roles/app-configure/templates/etc/systemd/system/app.service.j2` to
  - [ ] set `-Xms` to be `/32` of `ansible_memory_mb.real.total` (e.g `-Xms{{ (ansible_memory_mb.real.total/32) | int }}m`)
  - [ ] set `-Xmx` to be `/16` of `ansible_memory_mb.real.total`
  - **Note** that the there is **no** space in there. The result should look like `-Xms499m` and `-Xmx999m`
- [ ] Use `ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' backend-setup.yaml` where you replace `password` with the token I give you
- [ ] Run `docker exec --user root app cat /etc/systemd/system/app.service` and see how Ansible used the host characteristics to set the JVM settings
- [ ] Visit http://localhost:8080/greeting?name=ansible and make sure you see the message `Hello ansible` (Change the `name` param to anything you like)

---
## Discussion: Using Ansible data-structures

Ansible supports two kinds of datastructures—lists and dictionaries, along with mechanisms to iterate over them, and manipulate (combine, split, subloop) them.

```yaml
- name: Loop over a list of hashes
  debug:
    msg: "The name:{{ item.name }} has value:{{ item.value }}"
  with_items:
    # this is a "list of hashes or dictionaries"
    - { name: 'ansible', value: 'awesome' }
    - { name: 'CaC', value: true }
```

---
## Exercise: Using Ansible data-structures

- [ ] Refactor `app-configure` roles `tasks/main.yml` and combine the two `apt` tasks that install `wget` and `curl` into one using a loop over a list of hashes.
  Here's an example: `{ name: 'curl', value: '7.81.0-1ubuntu1.19' }`
- [ ] Use `ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' backend-setup.yaml` where you replace `password` with the token I give you
- [ ] Visit http://localhost:8080/greeting?name=ansible and make sure you see the message `Hello ansible` (Change the `name` param to anything you like)
- **NOTE** This is an exercise.
  It's NOT the most efficient way to install software using `apt` (or any package manager), because it installs software one at a time.
  Most modern package managers can be given a _list_ that it will install in one fell swoop, like so:
  ```yaml
  - name: Install libraries
    ansible.builtin.apt:
      name:
        - wget=1.21.2-2ubuntu1.1
        - curl=7.81.0-1ubuntu1.19
      state: present
      update_cache: yes
    become: true
  ```

---
## Discussion: Using tags

Ansible allows you to use tags to slice and dice which tasks should be applied under certain scenarios.
You can apply tags to roles (which indirectly means you are tagging all the tasks in that role), or individual tasks.

```yaml
- name: Use Ansible facts/filters
  debug:
    msg: "The total real memory available is {{ (ansible_memory_mb.real.total/32) | type_debug }}"
  tags:
    - test
```

You can now target tasks with a specific tag like so:

```bash
ansible-playbook -i environments/development/ \
  --extra-vars GITHUB_TOKEN='password' \
  --tags test \
  backend-setup.yaml
 ```

 Alternatively, you can _skip them_ with `--skip-tags`, like so:

```bash
ansible-playbook -i environments/development/ \
  --extra-vars GITHUB_TOKEN='password' \
  --skip-tags test \
  backend-setup.yaml
```

---
## Exercise: Using tags

- [ ] Tag some of the tasks in `roles/app-configure/tasks/main.yml`
- [ ] Use `ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' --tags <name-of-tag> backend-setup.yaml` where you replace `<name-of-tag>` with your tag name and `password` with the token I give you
- [ ] Notice which tasks run as listed by Ansible's output
- [ ] Use `ansible-playbook -i environments/development/ --extra-vars GITHUB_TOKEN='password' --skip-tags <name-of-tag> backend-setup.yaml` where you replace `<name-of-tag>` with your tag name and `password` with the token I give you
- [ ] Notice which tasks run as listed by Ansible's output
- [ ] Visit http://localhost:8080/greeting?name=ansible and make sure you see the message `Hello ansible` (Change the `name` param to anything you like)

---
## Discussion: Encrypting passwords using ansible-vault

Every so often you wish to store credentials in your Ansible scripts, and storing unencrypted credentials in version control is obviously a bad idea.
Ansible ships with `ansible-vault`, that allows you to encrypt and decrypt credentials.

There are multiple ways to store the password you need for decryption, and ways to have "vaults"—that hold the passwords for different "settings" (dev versus prod).
We will use the simplest way—store the password in a file.

```yaml
# ansible.cfg
[defaults]
# shortened for brevity
vault_identity_list = cac-vault-password
```

```bash
❯ ansible-vault encrypt_string --name GITHUB_TOKEN password
Encryption successful
GITHUB_TOKEN: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          35333965346166353631363733363664323562396164333837316265323065356338366138326435
          6436363163396634663335633163666330643363383935630a386562393630333866623162326565
          38383338653837613134323937643537356638336362623938653230666336326264393263663939
          6336626233333634610a393334373432363832383565346338303932353362653066643236393364
          3733
```

You can now store this as a variable in your repository, and all you need is to supply it the correct password file.

```bash
❯ ansible localhost -m ansible.builtin.debug -a var=GITHUB_TOKEN -e @environments/development/group_vars/backend
[WARNING]: No inventory was parsed, only implicit localhost is available
localhost | SUCCESS => {
    "GITHUB_TOKEN": "password"
}
```

---
## Exercise: Encrypting passwords using `ansible-vault`

- [ ] Encrypt the `GITHUB_TOKEN` using `ansible-vault`.
  Remember, you don't have to do anything with `ansible.cfg`.
- [ ] Use the value produced by `ansible-vault` and introduce the `GITHUB_TOKEN` in `environments/development/group_vars/backend`
- [ ] Run `ansible-playbook -i environments/development/ backend-setup.yaml` to make sure all is well
- [ ] Visit http://localhost:8080/greeting?name=ansible and make sure you see the message `Hello ansible` (Change the `name` param to anything you like)

---
## Discussion: Checking your scripts

Ansible ships with some capabilities to check your scripts.
The first is the `--syntax-check` flag

```bash
ansible-playbook -i environments/development backend-setup.yaml --syntax-check
```

You can also check which hosts will get affected (great idea if you are running this against production!)

```bash
ansible-playbook -i environments/development backend-setup.yaml --list-hosts
```

And finally, you can limit which hosts get affected (assuming you had more than one target servers)

```bash
 ansible-playbook -i environments/development backend-setup.yaml --limit app
```
---
## Discussion: Benefits

- Simple
- Plain text
- Huge module and role ecosystem via Ansible Galaxy
- Reasonable installation expectations
- CLI friendly

---
## Discussion: Trade-offs

- No prescribed workflows
- Push based mode

---
## Discussion: Usage (Deployment orchestration)

- Ordered deployments
- Zero-downtime
- Blue/Green deployments

---
## Discussion: Notes

- Ansible offers [many places](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence) to declare variables.
  **You do not have to use all of them!**
  This can get confusing very fast.
- Roles are about re-use.
  Be sure to check out [Ansible Galaxy](https://galaxy.ansible.com/ui/) for community generated and shared roles.
- Ansible has a huge ecosystem of proprietary and open-source tools.
  Be sure to check out the following:
  - Linting with [ansible-lint](https://github.com/ansible/ansible-lint)
  - Testing roles with [Molecule](https://ansible.readthedocs.io/projects/molecule/)
  - Proprietary [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible/automation-controller)
  - So many [others](https://docs.ansible.com/ansible/latest/community/other_tools_and_programs.html)!

---
## Thanks

---
## Discussion: Helpful tips

```bash
# if you messed up a container, just restart it!
# in our case we only have two containers—web and app
docker container stop <name-of-container>

# to restart the web container
docker container run --rm --name web -d -t -p 8080:80 --network cac cac-with-ansible:1.0.0

# to restart the app container
docker container run --rm --name app -d -t -p 9000:8080 --network cac cac-with-ansible:1.0.0
```

