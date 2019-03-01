plugins = {
  'ansicolor'    => '0.6.2',
  'apache-httpcomponents-client-4-api'    => '4.5.5-3.0',
  'jackson2-api'    => '2.9.8',
  'aws-java-sdk'    => '1.11.457',
  'cloudbees-folder'    => '6.7',
  'cors-filter'    => '1.1',
  'junit'    => '1.27',
  'workflow-step-api'    => '2.19',
  'token-macro'    => '2.6',
  'cucumber-reports'    => '4.4.0',
  'script-security'    => '1.53',
  'matrix-project'    => '1.13',
  'javadoc'    => '1.4',
  'email-ext'    => '2.64',
  'workflow-scm-step'    => '2.7',
  'ssh-credentials'    => '1.14',
  'jsch'    => '0.1.55',
  'git-client'    => '2.7.6',
  'git'    => '3.9.3',
  'github-api'    => '1.95',
  'plain-credentials'    => '1.5',
  'github'    => '1.29.4',
  'ghprb'    => '1.42.0',
  'gradle'    => '1.30',
  'greenballs'    => '1.15',
  'groovy'    => '2.1',
  'jquery'    => '1.12.4-0',
  'maven-plugin'    => '3.2',
  'maven-repo-cleaner'    => '1.2',
  'multiple-scms'    => '0.6',
  'rebuild'    => '1.29',
  'matrix-auth'    => '2.3',
  'description-setter'    => '1.10',
  'run-condition'    => '1.2',
  'parameterized-trigger'    => '2.35.2',
  'job-dsl'    => '1.71',
  'seed'    => '2.1.4',
  'snsnotify'    => '1.13',
  'sonar'    => '2.8.1',
  'ssh-agent'    => '1.17',
  'ssh-slaves'    => '1.29.4',
  'workflow-support'    => '3.2',
  'durable-task'    => '1.29',
  'workflow-durable-task-step'    => '2.29',
  'resource-disposer'    => '0.12',
  'ws-cleanup'    => '0.37',
  'scm-api'    => '2.3.0',
  'mailer'    => '1.23',
  'structs'    => '1.17',
  'jdk-tool'    => '1.2',
  'command-launcher'    => '1.3',
  'credentials'    => '2.1.18',
  'workflow-api'    => '2.33',
  'envinject'    => '2.1.6',
  'conditional-buildstep'    => '1.3.6',
  'bouncycastle-api'    => '2.17',
  'envinject-api'    => '1.5',
  'display-url-api'    => '2.3.0',
  'icon-shim'    => '2.0.3',
  'workflow-job'    => '2.31',
  'ace-editor'    => '1.1',
  'workflow-cps-global-lib'    => '2.13',
  'jquery-detached'    => '1.2.1',
  'workflow-cps'    => '2.63',
  'git-server'    => '1.7',
  'pipeline-milestone-step'    => '1.3.1',
  'pipeline-input-step'    => '2.9',
  'pipeline-stage-step'    => '2.3',
  'pipeline-graph-analysis'    => '1.9',
  'pipeline-rest-api'    => '2.10',
  'handlebars'    => '1.1.1',
  'momentjs'    => '1.1.1',
  'pipeline-stage-view'    => '2.10',
  'pipeline-build-step'    => '2.7',
  'credentials-binding'    => '1.18',
  'pipeline-model-api'    => '1.3.4.1',
  'pipeline-model-extensions'    => '1.3.4.1',
  'branch-api'    => '2.1.2',
  'workflow-multibranch'    => '2.20',
  'authentication-tokens'    => '1.3',
  'docker-commons'    => '1.13',
  'workflow-basic-steps'    => '2.14',
  'docker-workflow'    => '1.17',
  'pipeline-stage-tags-metadata'    => '1.3.4.1',
  'pipeline-model-declarative-agent'    => '1.1.1',
  'pipeline-model-definition'    => '1.3.4.1',
  'lockable-resources'    => '2.4',
  'workflow-aggregator'    => '2.6',
  'aws-credentials'    => '1.26',
  'pipeline-aws'    => '1.36'
}

plugins.each_with_index do |(plugin_name, plugin_version), index|
  jenkins_plugin plugin_name do
    action  :install
    install_deps false
    # only restart on the final plugin
    if index == (plugins.size - 1)
      notifies :restart, 'service[jenkins]', :immediately
    end
  end
end