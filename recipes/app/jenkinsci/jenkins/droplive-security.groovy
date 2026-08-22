import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm
import jenkins.model.Jenkins

def password = System.getenv('JENKINS_ADMIN_PASSWORD')
if (!password) {
    throw new IllegalStateException('DropLive must generate the Jenkins admin password')
}

def jenkins = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
realm.createAccount('admin', password)
jenkins.setSecurityRealm(realm)

def authorization = new FullControlOnceLoggedInAuthorizationStrategy()
authorization.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(authorization)
jenkins.save()
