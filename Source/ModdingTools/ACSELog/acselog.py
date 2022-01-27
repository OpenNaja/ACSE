from __future__ import print_function
import frida
import sys
import os

def on_message(message, data):
    print("[%s] => %s" % (message, data))

def on_detached(message, data):
    if message == 'process-terminated':
        sys.exit(1)

def init(target_process):
    pass


def main(target_process):
    print('Looking for process..');
    loopwait = False
    while loopwait == False:
        try:
            session = frida.attach(target_process)
            loopwait = True
        except frida.ProcessNotFoundError:
            pass
        except:
            loopwait = True


    os.system('cls')

    script = session.create_script("""

    var CreateFileW = Module.getExportByName('kernel32.dll', 'CreateFileW');
    console.log("Logging function found");

    Interceptor.attach(CreateFileW, { // Intercept calls to our CreateFileW function

        // When function is called, print out its parameters
        onEnter: function (args) {
           var path = args[0].readUtf16String();
           if ( path.startsWith("acse :") ) {
              console.log( path.substr(6) );
           }
        },

        // When function is finished
        onLeave: function (retval) {
            //console.log('[+] Returned from CreateFileW: ' + retval);
        }
    });


""")
    script.on('message', on_message)
    session.on('detached', on_detached)
    script.load()
    print("[!] Ctrl+D on UNIX, Ctrl+C or Ctrl+Z on Windows/cmd.exe to stop.\n\n")
    sys.stdin.read()
    session.detach()

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: %s <process name or PID>" % __file__)
        sys.exit(1)

    try:
        target_process = int(sys.argv[1])
    except ValueError:
        target_process = sys.argv[1]
    main(target_process)