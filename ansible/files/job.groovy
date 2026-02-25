pipelineJob('restaurant-ci-cd') {

    description('Automated CI/CD pipeline for streamlit application')

    properties {
        disableConcurrentBuilds()
    }

    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/unixanand/Automated-CI-CD-Pipeline.git')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkins/Jenkinsfile')
            lightweight(true)
        }
    }

    triggers {
        githubPush()
    }
}