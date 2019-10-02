const AWS = require('aws-sdk');
const {Storage} = require('@google-cloud/storage');

exports.handler = async function(event, context) {
  let s3 = new AWS.S3({apiVersion: '2006-03-01'});
  let gcpStorage = new Storage();
  let gcpBucket = gcpStorage.bucket(process.env['GCP_BUCKET']);

  let promises = event.Records.map(r => {
    let bucketName = r.s3.bucket.name;
    let key = r.s3.object.key;
    let params = { Bucket: bucketName, Key: key };

    process.stdout.write(`Sending ${bucketName}/${key} to Google Storage...`);

    let os = gcpBucket.file(key).createWriteStream();
    let promise = new Promise(function(resolve, reject) {
      s3.getObject(params)
        .createReadStream()
        .pipe(os)
        .on('error', (err) => reject(err))
        .on('finish', () => resolve());
    });

    return promise;
  });

  await Promise.all(promises);

  process.stdout.write(`Processed ${promises.length} files...`);
};