from rdagent.utils.env import DockerEnv, KGDockerConf
 
de = DockerEnv(KGDockerConf())
de.prepare()
de.run("cat train.py", running_extra_volume={"/home/v-yuanteli/mle-bench/agents/rdagent/spaceship-titanic_template": "/workspace/kg_workspace"})