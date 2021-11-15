package main

import (
    "os"
    "fmt"
    "time"
    // "math/rand"
)

func main() {

    counter := 0
    for {
        const filename = "/etc/shadow"
        fmt.Println("%d - Sleeping 1 second and reading sensitive file: %s", counter, filename)
        time.Sleep(5 * time.Second)
        // treinta := rand.Int31n(30)
        // time.Sleep(time.Duration(treinta) * time.Second)
        file, _ := os.Open(filename)
        defer file.Close()
        counter = counter + 1
    }
}

// https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/read_sensitive_file_untrusted.go
// 17:46:16.927652071: Warning Sensitive file opened for reading by non-trusted program (
//     user=root
//     user_loginuid=0
//     program=read_sens_file
//     command=read_sens_file
//     file=/etc/shadow
//     parent=systemd
//     gparent=<NA>
//     ggparent=<NA>
//     gggparent=<NA>
//     container_id=host
//     image=<NA>)
//     k8s.ns=<NA>
//     k8s.pod=<NA>
//     container=host

// func main() {

//     counter := 0
//     for {
//         const filename = "/etc/shadow"
//         // treinta := rand.Int31n(30)
//         // time.Sleep(time.Duration(treinta) * time.Second)
//         file, _ := os.Open(filename)
//         defer file.Close()
//         fmt.Println("%d - Sleeping 1 second and reading sensitive file: %s", counter, filename)
//         time.Sleep(15 * time.Second)
//         counter = counter + 1
//     }
// }

