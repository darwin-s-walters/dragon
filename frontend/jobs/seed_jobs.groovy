import javaposse.jobdsl.dsl.*

pipelineJob('frontend-deploy') {
    definition {
        cpsScm {
            scm {
                git('https://github.com/ICFI/dragon.git')
            }
            scriptPath("frontend/jobs/scripts/deploy_frontend")
        }
    }
}

pipelienJob('create-users') {
    definition {
        cpsScm {
            scm {
                git('https://github.com/ICFI/dragon.git')
            }
            scriptPath("frontend/jobs/scripts/create_users")
        }
    }
} 