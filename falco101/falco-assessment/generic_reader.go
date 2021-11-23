package main

import (
    "os"
    "fmt"
    "time"
    "strconv"
)

// 
// This is a dummy program that opens a file or dir for reading.
// Its goal is to demo rule open_sens_file of Falco.
// 
// It sleeps and opens some files for reading. 
// Call this program with It opens the files provided 
// as 2nd, 3rd, ..., Nth arguments.
// Files or directories are accepted, but they might exist
// in order to trigger the Falco Rule.
// 
func main() {
    
    // invoque with 
    //   1. number of seconds to sleep
    //   1. number of repetitions
    //   2. list of files to read
    if len(os.Args) < 4 {
        fmt.Printf("Usage : %s <reps> <wait_interval> <file1|dir1> <file2|dir2> ... \n ", os.Args[0]) // return the program name back to %s
        os.Exit(1) // graceful exit
      }

    reps_s := os.Args[1]
    reps, _ := strconv.Atoi(reps_s)
    seconds_s := os.Args[2]
    seconds, _ := strconv.Atoi(seconds_s)
    prog_args := os.Args[3:]
    fmt.Printf("Exec plan: repeat %d times, sleeping %d seconds and reading:\n   %s\n\n", reps, seconds, prog_args)

    counter := 0
    for counter < reps {
        fmt.Printf("%d - Read and sleep %d seconds.\n", counter, seconds)

        for _, files_by_arg := range prog_args {
            fmt.Printf("\tReading file: %s --- ", files_by_arg)
            file, err := os.Open(files_by_arg)
            if err != nil {
                fmt.Printf("ERROR: %s\n", err)
            } else {
                fmt.Printf("OK\n")
            }
            defer file.Close()
        }
        time.Sleep(time.Duration(seconds) * time.Second)
        counter = counter + 1
    }
}

// https://github.com/falcosecurity/event-generator/blob/b8ed1a9420ff46926b5bf936832f1af1f799cd5c/events/syscall/read_sensitive_file_untrusted.go
// 17:46:16.927652071: Warning Sensitive file opened for reading by non-trusted program (
//     user=root
//     user_loginuid=0
//     program=<binary_name_provided_at_dockerfile_build_time>
//     command=<binary_name_provided_at_dockerfile_build_time>
//     file=<file_passed_as_argument>
//     parent=systemd
//     gparent=<NA>
//     ggparent=<NA>
//     gggparent=<NA>
//     container_id=host
//     image=<NA>)
//     k8s.ns=<NA>
//     k8s.pod=<NA>
//     container=host