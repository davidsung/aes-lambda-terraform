exports.handler = async function(event, context) {
    console.log("EVENT: \n" + JSON.stringify(event, null, 2))
    const response = {
        statusCode: 200,
        body: JSON.stringify(`Hello world!`)
    };

    return response;
}