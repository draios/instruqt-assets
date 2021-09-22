---
title: "Rules"
weight: 005
chapter: false
---

## What is a Falco rule?

In essence, a Falco Rule is a just condition under which an alert should be generated whenever the condition is met. You use Falco rules to target specific events in your system you'd like to be alerted about. It can be anything, even a particular file open for reading!

Let's see a real use-case. Imagine you want to be notified when a *shell is spawned* in one of your containers (this rule exists and it is included by default with Falco in *falco_rules.yaml*. You can execute the next command to see how it looks:

```BASH
cat /etc/falco/falco_rules.yaml | grep -A 12 "rule: Terminal shell"
 
``` 

You'll find the next fields:

 - **rule**: a short unique name for the rule.
 - **desc**: a longer description of what the rule detects.
 - **condition**: a filtering expression that is applied against events to see if they match the rule.
 - **output**: it specifies the message that should be output if a matching event occurs, and follows the Sysdig output format syntax.
 - **priority**: a case-insensitive representation of severity. It can take the next values:
  - *emergency*
  - *alert*
  - *critical*
  - *error*
  - *warning*
  - *notice*
  - *informational*
  - *debug*


There's no better way to test what you learned than creating your own custom rule and triggering it with an event!


### Creating your first custom rule

To become acquainted with rules, you are going to create a *lighter* version of the *Terminal shell in container* rule in your custom rules file. 

1. Open an editor and write it yourself instead of copy/paste (writing it yourself will make a difference in this learning process!). First, define rule name and description:

  ```
- rule: workshop_shell_in_container
  desc: notice shell activity within a container
```

2. After this, define the condition. Here it is where the magic happens. You want to specify that the event is triggered by a process running inside of a container:

  ```
  condition: container.id != host
```  
    But you also want to be alerted when this process is *bash*:

  ```
  condition: container.id != host and proc.name = bash
```      

    This should be enough. But let's include too another condition to filter out some of the associated system calls with the event of creating a new shell inside of a container. You want to be notified just when the syscall is of *openat* type. This is not perfect filtering, but will reduce some noise:

  ```
  condition: container.id != host and proc.name = bash and evt.type=openat
```  

3. Now, you just need to define the output and priority level. Here you define the information provided by Falco when the event is met. For example, let's include a brief description and the container name:

  ```
  output: falco_AWS_workshop shell in a container container_name=%container.name
  priority: WARNING
```


4. It the end, you should have something like this:

  ```
- rule: workshop_shell_in_container
  desc: notice shell activity within a container
  condition: container.id != host and proc.name = bash and evt.type=openat
  output: falco_AWS_workshop shell in a container container_name=%container.name
  priority: WARNING
```


### Applying the new rule

To apply your new rule, let's put everything together and write it to your falco_rules.local.yaml file (you can use the command in here or build it within your editor, the result should be the same). The owner of this file is root, so let's avoid permission issues logging as root. The last command reloads the Falco configuration and restarts the engine with any new change to config and rules. Let's back up the file *falco_rules.local.yaml* on your workstation, then update it to include your new *shell_in_container* rule:

```bash
sudo -i
sudo cp /etc/falco/falco_rules.local.yaml /etc/falco/falco_rules.local.yaml.BAK
sudo cat  <<EOF >> /etc/falco/falco_rules.local.yaml
- rule: workshop_shell_in_container
  desc: notice shell activity within a container
  condition: container.id != host and proc.name = bash and evt.type=openat
  output: falco_AWS_workshop shell in a container container_name=%container.name
  priority: WARNING
EOF
exit
sudo systemctl restart falco
 
```

And your rule is created! Check with Falco -L that the syntax is all right before testing it. You should get no errors and the new rule listed if everything went good.

```bash
falco -L
 
```

If you get any error, do not worry: this is the normal process. Review the steps before and fix it. The error output will give you some hints about what is happening with the new rule.

### Triggering an alert

Now let's trigger an alert to observe how it works:

1. In the right-side terminal, deploy a basic *nginx* web server and check that it works with: 

  ```BASH
docker run --rm -d -p 8080:80 --name web nginx
docker ps 
sleep 2
curl localhost:8080
 
```

2. Once the server is up and running, run a shell in that container:

  ```BASH
docker exec -it web /bin/bash
exit
 
```

3. In the left-side terminal, execute:

  ```log
$ cat /var/log/falco_events.log 
 
```

    And you should see something like this

  ```LOG
16:05:24.687415867: Notice A shell was spawned in a container with an attached terminal (user=root web (id=b7a1d8d4cb6c) shell=bash parent=runc cmdline=bash terminal=34817 container_id=b7a1d8d4cb6c image=nginx)
16:05:24.687705210: Warning falco_AWS_workshop: shell in a container container_name=web
16:05:24.687709559: Warning falco_AWS_workshop: shell in a container container_name=web
  ```

You can see that both the original rule and your custom rule were triggered, as they target the same event. But they are not exactly the same. The original rule is composed of `macros` and `lists`. Apart from *rules*, a Falco YAML file may contain these other kinds of elements.  These two elements provide more flexibility and power to define your rules. In the next steps, you'll practice how to use them!






<!-- 
For example, check how the rule `write_binary_dir` uses the macro `bin_dir` that uses the list `bin_dirs`:

```
- list: bin_dirs
  items: [/bin, /sbin, /usr/bin, /usr/sbin]

- macro: bin_dir
  condition: fd.directory in (bin_dirs)

- rule: write_binary_dir
  desc: an attempt to write to any file below a set of binary directories
  condition: bin_dir and evt.dir = < and open_write and not package_mgmt_procs
  output: "File below a known binary directory opened for writing (user=%user.name command=%proc.cmdline file=%fd.name)"
  priority: WARNING
```
 -->
