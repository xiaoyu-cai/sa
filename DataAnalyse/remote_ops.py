__author__ = 'xiaoyu'
import pexpect
import os
import sys

OKRED = "\033[91m"
ENDC = "\033[0m"


class RemoteOps():

    def __init__(self):
        self.server_info = [
            {
                'ip': '192.168.1.9',
                'password': '2323232',
            },
            {
                'ip': '192.168.1.7',
                'password': 'efsesf',
            }
        ]

    def scp_script(self, script_path, dst_path):
        if not os.path.exists(script_path):
            print "%sscript [%s] is not exist%s" %  (OKRED, script_path, ENDC)
            return
        for server in self.server_info:
            print "copy the script to host %s" % server['ip']
            scp = pexpect.spawn('scp %s root@%s:%s' % (script_path, server['ip'], dst_path))
            print ('scp %s root@%s:%s' % (script_path, server['ip'], dst_path))
            try:
                i = scp.expect(['password:', 'continue connecting (yes/no)?'], timeout=200)
                if i == 0:
                    print "Need Password"
                    scp.sendline(server['password'])
                elif i == 1:
                    print "yes or no?"
                    scp.sendline('yes\n')
                    print "Need Password"
                    scp.expect('password:')
                    scp.sendline(server['password'])
                    scp.expect('100%')
                print 'done\n'
            except pexpect.EOF:
                print("scp %s to %s EOF" % (script_path, server['ip']))
                scp.close()
            except pexpect.TIMEOUT:
                print("scp %s on %s TIMEOUT" % (script_path, server['ip']))
                scp.close()

    def run_script(self, cmd):
        print "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        print "   Start running the script on remote host!!  "
        print "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n"
        for server in self.server_info:
            print "\nrun script on host %s" % server['ip']
            ssh = pexpect.spawn('ssh root@%s "%s"' % (server['ip'], cmd))
            i = ssh.expect(['password:', 'continue connecting (yes/no)?'], timeout=200)
            if i == 0 :
                print "Need Password"
                ssh.sendline(server['password'])
            elif i == 1:
                ssh.sendline('yes\n')
                ssh.expect('password: ')
                ssh.sendline(server['password'])
                ssh.sendline(cmd)
                r = ssh.read()
                print r
            print "done"
            try:
                pass
            except pexpect.EOF:
                print("run_script %cmd on %s EOF" % (cmd, server['ip']))
                ssh.close()
            except pexpect.TIMEOUT:
                print("run_script %cmd on %s TIMEOUT" % (cmd, server['ip']))
                ssh.close()

def usage():
    print "\nrun the script attached on a set of IPs"
    print "%sWarning: Inject IPs in script %s" % (OKRED,ENDC)

    if len(sys.argv) < 2:
      print "\t usage: ./app run_scripts"
      sys.exit()
    print "\n"

if __name__ == '__main__':
    usage()
    script=sys.argv[1]
    if len(sys.argv) > 2:
        arg = ' '.join(sys.argv[2:])

    src=os.getcwd()
    src_file=src+'/'+script
    dst='/tmp/'
    dst_file=dst+script

    remote_ops = RemoteOps()
    remote_ops.scp_script(src_file, dst_file)

    cmd = "chmod +x %s;sh %s %s" % (dst_file, dst_file, arg)
    remote_ops.run_script(cmd)
else:
  version="0.1"
  print "Import test.py"