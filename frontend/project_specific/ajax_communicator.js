class AjaxCommunicator {
  static send(type, urlArg, dataArg = {}) {
    console.log(`AjaxCommunicator#send: type: ${type}, urlArg: ${urlArg}, dataArg: ${JSON.stringify(dataArg)}`);
    return $.ajax({
      type,
      url: urlArg,
      data: dataArg,
      dataType: 'script'
    });
  }
  static post(urlArg, dataArg = {}) {
    console.log(`AjaxCommunicator#post: urlArg: ${urlArg}, dataArg: ${JSON.stringify(dataArg)}`);
    return this.send('POST', urlArg, dataArg);
  }
  static get(urlArg) {
    console.log(`AjaxCommunicator#get: urlArg: ${urlArg}`);
    return this.send('GET', urlArg);
  }
}
export default AjaxCommunicator;
