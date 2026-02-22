pipelineJob('restaurant-ci-cd') {

    properties {
        disableConcurrentBuilds()
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://https://github.com/unixanand/Automated-CI-CD-Pipeline.git')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkins/Jenkinsfile')
        }
    }

    triggers {
        githubPush()
    }
}