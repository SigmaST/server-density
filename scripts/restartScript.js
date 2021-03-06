import com.hivext.api.environment.Environment;

var APPID = hivext.local.getParam("TARGET_APPID"),
    SESSION = hivext.local.getParam("session"),
    procedureName = "restartAgent",
    oEnvService,
    envInfoResponse,
    aActions = [],
    iterator,
    softNode,
    softNodeProperties,
    nodes;

oEnvService = hivext.local.exp.wrapRequest(new Environment(APPID, SESSION));
envInfoResponse = oEnvService.getEnvInfo();

if (!envInfoResponse.isOK()) {
    return envInfoResponse;
}

nodes = envInfoResponse.getNodes();
iterator = nodes.iterator();

while(iterator.hasNext()) {
    softNode = iterator.next();
    softNodeProperties = softNode.getProperties();

    aActions.push({
        procedure : procedureName,
        params : {
            nodeType : softNodeProperties.getNodeType()
        }
    });
}

return {
    result: 0,
    onAfterReturn: {
        call : aActions
    }
};