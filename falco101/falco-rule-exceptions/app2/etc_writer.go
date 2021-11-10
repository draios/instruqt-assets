package main

import (
	"io/ioutil"
	"os"
    "fmt"
    "time"
)

// https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/write_below_etc.go
func main() {

    counter := 0
    for {
        const filename = "/etc/binary"
        fmt.Println("%d - Sleeping 15 seconds and writing to %s", counter, filename)
        time.Sleep(time.Second * 15)
        defer os.Remove(filename)
        ioutil.WriteFile(filename, nil, os.FileMode(0755))
        counter = counter + 1
    }
}


// 20:52:35.802925050: Error File below /etc opened for writing (user=root\
//      user_loginuid=-1\
//      command=etc_writer\
//      parent=<NA>\
//      pcmdline=<NA>\
//      file=/etc/binary\
//      program=etc_writer\
//      gparent=<NA>\
//      ggparent=<NA>\
//      gggparent=<NA>\
//      container_id=8dee55e866ba\
//      image=docker.io/sysdigtraining/etc_writer)\
//      k8s.ns=app2\
//      k8s.pod=etc-writer-6bdddc8975-d4znw\
//      container=8dee55e866ba