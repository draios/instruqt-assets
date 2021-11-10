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
        fmt.Println("%d - Sleeping 1 second and writing to %s", counter, filename)
        time.Sleep(time.Second)
        defer os.Remove(filename)
        ioutil.WriteFile(filename, nil, os.FileMode(0755))
        counter = counter + 1
    }
}

