import os
from os.path import basename, join, exists
from utils import cd
import subprocess
import logging
import sys
import tempfile
from glob import glob

logger = logging.getLogger(__name__)

class Tester:

    def __init__(self, config, oracle, workdir):
        self.config = config
        self.oracle = oracle
        self.workdir = workdir

    def __call__(self, project, test, dump=None, trace=None, load=None, klee=False, env=os.environ, check_instrumented=False):
        src = basename(project.dir)
        if klee:
            logger.info('running test \'{}\' of {} source with KLEE'.format(test, src))
        else:
            if not self.config['mute_test_message']:
                logger.info('running test \'{}\' of {} source'.format(test, src))
        environment = dict(env)
        if self.config['m32']:
            PATH=os.environ['PATH'].split(':')
            for x,y in [(os.environ['KLEE_DIR'],os.environ['KLEE_32_DIR']), (os.environ['LLVM2_DIR'],os.environ['LLVM2_32_DIR'])]:
                SRC=x+"/Release+Asserts/bin"
                SRC_32=y+"/Release+Asserts/bin"
                found=False
                for i,l in enumerate(PATH):
                    if os.path.abspath(SRC)== os.path.abspath(l):
                        ll = os.path.abspath(SRC_32)
                        PATH[i]=ll
                        found=True
                if not found:
                    PATH.insert(0,f"{SRC_32}")
            environment['PATH'] = ":".join(PATH)

            LDLIBPATH=os.environ['LD_LIBRARY_PATH'].split(':')
            found=False
            KLP=os.environ['KLEE_LIBRARY_PATH']
            KLP_32=KLP+"/32"
            STP=os.environ['STP_DIR']+"/build/lib"
            STP_32=os.environ['STP_DIR']+"/build32/lib"
            for x,y,z in [(KLP,KLP_32,'/32'),(STP,STP_32,'build32/lib')]:
                found=False
                update_needed = not x.endswith(z)
                if not update_needed: 
                    y=x
                    offset=-1*(len(z))
                    x=x[0:offset]
                for i,l in enumerate(LDLIBPATH):
                    if os.path.abspath(l)==os.path.abspath(x):
                        LDLIBPATH[i]=y
                        found=True
                if not found:
                    LDLIBPATH.insert(0,f"{y}")
                logger.info('32b executable, "LD_LIBRARY_PATH" with "{}"'.format(y))
            llp=":".join(LDLIBPATH); 
            environment['LD_LIBRARY_PATH'] = llp[0:-1] if llp[-1]==':' else llp

        if dump is not None:
            environment['ANGELIX_WITH_DUMPING'] = dump
            reachable_dir = join(dump, 'reachable')  # maybe it should be done in other place?
            os.mkdir(reachable_dir)
        if trace is not None:
            environment['ANGELIX_WITH_TRACING'] = trace
        if (trace is not None) or (dump is not None) or (load is not None):
            environment['ANGELIX_RUN'] = 'angelix-run-test'
        if klee:
            environment['ANGELIX_RUN'] = 'angelix-run-klee'
            # using stub library to make lli work
            environment['LLVMINTERP'] = 'lli -load {}/libkleeRuntest.so'.format(os.environ['KLEE_LIBRARY_PATH'])
            if self.config['m32']:
                environment['LLVMINTERP'] = 'lli -load {}/32/libkleeRuntest.so'.format(os.environ['KLEE_LIBRARY_PATH'])
        if load is not None:
            environment['ANGELIX_WITH_LOADING'] = load
        environment['ANGELIX_WORKDIR'] = self.workdir
        environment['ANGELIX_TEST_ID'] = test

        dirpath = tempfile.mkdtemp()
        executions = join(dirpath, 'executions')

        environment['ANGELIX_RUN_EXECUTIONS'] = executions

        if self.config['verbose'] and not self.config['mute_test_message']:
            subproc_output = sys.stderr
        else:
            subproc_output = subprocess.DEVNULL

        with cd(project.dir):
            proc = subprocess.Popen(self.oracle + " " + test,
                                    env=environment,
                                    stdout=subproc_output,
                                    stderr=subproc_output,
                                    shell=True)
            if klee or self.config['test_timeout'] is None: # KLEE has its own timeout
                code = proc.wait()
            else:
                code = proc.wait(timeout=self.config['test_timeout'])

        instrumented = True
        if dump is not None or trace is not None or klee:
            if exists(executions):
                with open(executions) as file:
                    content = file.read()
                    if len(content) > 1:
                        logger.warning("ANGELIX_RUN is executed multiple times by test {}".format(test))
                        instrumented = False
            else:
                if not self.config['mute_test_message']:
                    logger.warning("ANGELIX_RUN is not executed by test {}".format(test))
                    instrumented = False

        if check_instrumented:
            return (code == 0, instrumented)
        else:
            return code == 0
