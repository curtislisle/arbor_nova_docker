import girder_client

# create a client object
gc = girder_client.GirderClient(apiUrl='http://localhost:8080/girder/api/v1')
#authenticate with the target girder instance
login = gc.authenticate('anonymous','letmein')
# create the basic assetstore so later clients can use this new girder instances
newasset = gc.sendRestRequest('POST','assetstore',{'name':'assets','type':0,'root':'/assets'})
#print(newasset)