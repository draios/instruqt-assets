package main

import (
    "os/exec"
)

func main() {
    exec.Command("bash", "-c", "ls > /tmp/pableras").Run()
}


// package main

// import (
//     "fmt"
//     "time"
//     "os"
//     "os/exec"
//     "io/ioutil"
//     "path/filepath"
// )

// // https://github.com/falcosecurity/event-generator/blob/71efb9214db03b116964091c5050984f2f0f6826/events/helper/run_shell.go
// // https://github.com/falcosecurity/event-generator/blob/71efb9214db03b116964091c5050984f2f0f6826/pkg/runner/helper.go

// func RunShell() error {
// 	return exec.Command("bash", "-c", "ls > /dev/null").Run()
// }

// func SpawnAs(name string, action string, args ...string) error {
// 	fullArgs := append([]string{fmt.Sprintf("^%s$", action)}, args...)

// 	tmpDir, err := ioutil.TempDir(os.TempDir(), "falco-event-generator")
// 	if err != nil {
// 		return err
// 	}
// 	defer os.RemoveAll(tmpDir)

// 	name = filepath.Join(tmpDir, name)
//     path, err := os.Executable()
// 	if err := os.Symlink(path, name); err != nil {
// 		return err
// 	}

// 	cmd := exec.Command(name, append(args, fullArgs...)...)

// 	stdout, err := cmd.Output()
// 	fmt.Println("%s command stdout", stdout)

// 	if err := cmd.Run(); err != nil {
// 		return err
// 	}

// 	return nil
// }


// func main() {
//     counter := 0
//     for {
//         fmt.Println("%d - Sleeping 1 second and executing command", counter)
//         time.Sleep(time.Second)
//         SpawnAs("echo", "RunShell")
//         counter = counter + 1
//     }
// }








    // counter := 0
    // for {
    //     time.Sleep(time.Second)
    //     var shelll string = "bash"
    //     var action string = "-c"
    //     const args = "ls > /dev/null"
    //     // fullArgs := append([]string{fmt.Sprintf("^%s$", action)}, args)
        
    //     fmt.Println("%d - Sleeping 1 second and executing command %s", counter, shelll)
        
    //     tmpDir, err := ioutil.TempDir(os.TempDir()
    //     if err != nil {
    //        fmt.Println(err) 
    //     }   
    //     defer os.RemoveAll(tmpDir)
        
    //     var shelll2 string = filepath.Join(tmpDir, shelll)
    //     if err := os.Symlink(shelll, shelll2); err != nil {
    //        fmt.Println(err) 
    //     }   
        
    //     cmd := exec.Command(shelll2, action, args)
    //     stdout, err := cmd.Output()

    //     if err != nil {
    //         fmt.Println(err.Error())
    //         return
    //     }

    //     fmt.Println(string(stdout))

    //     counter = counter + 1
    // }   
