# Updating HMRC Basic PAYE Tools

HMRC provides free PAYE software for small businesses to download from GOV.UK. As Mainstream Publisher doesn't have the functionality for content designers to directly upload files, this has to be done as a manual task by developers.

This work will come through to us as a Zendesk ticket, with a GDS content designer as our primary contact and the files available for download through the ticket.

## Verifying the files

We should receive three files from HMRC:

A `.zip` of the project files
- `BPT_{version_number}_GDS.zip` - a zip file containing:
  - `payetools-rti-{version_number}-{win | osx | linux}.zip` (three files, one for each OS)
  - `payetools-rti-patch-{version_number}-win.zip`
  - `realtimepayetools-update-v{xx}.xml`
  - `test-realtimepayetools-update-v{xx}.xml`
  - `deployment-instructions.xml`
  - `bpt-release-info.txt`

Two sets of expected SHA256 sums for the provided files

- `BPT_{version_number}_GDS.zip.sha256sum.txt` to verify the zip file itself
- `BPT_{version_number}_GDS.sha256sum.txt` to verify the content individually

Both the SHA sum files are will be formatted to be compatible with `shasum` to allow for bulk verification.

1) Download all three files from the Zendesk ticket
2) Verify the zip file
```bash
shasum -a 256 -c BPT_{version_number}_GDS.zip.sha256sum.txt
```

3) Extract the contents of the zip into a new directory 
4) From inside that directory, verify the individual files

```bash
shasum -a 256 -c ../BPT_{version_number}_GDS.sha256sum.txt
```

Do not extract the `paytools-rti` `.zip` files, these should be uploaded as `.zips`.

## Initial upload and testing

In order to place these files correctly in HMRC's download location, we must manually upload them to Asset Manager.

Standard instructions for uploading assets to Asset Manager can be found [here](https://docs.publishing.service.gov.uk/manual/manage-assets.html), but the steps we need to follow for this task are different.

1) Retrieve the name of an individual Asset Manager Production pod
```bash
POD=$(basename $(kubectl get pods -l app=asset-manager -o name | head -1))
echo $POD
```
2) Upload the `test-realtimepayetools-update-v{xx}.xml` file, and the four `payetools-rti ... .zip` files
```bash
kubectl cp {file} apps/$POD:/tmp
```
3) Open a bash session on the pod, make sure that the metadata `.xml` and the four `.zip` files are present in the `/tmp` directory, and that no other `.zip` files are present.
```bash
kubectl exec -it $POD -- bash
```
4) Run the rake task to create the metadata file as an Asset
```bash
bundle exec rake govuk_assets:create_hmrc_paye_asset[tmp/test-realtimepayetools-update-v{xx}.xml]
```
5) Run the rake task to bulk create the zip files as Assets
```bash
bundle exec rake govuk_assets:create_hmrc_paye_zips[tmp]
```
6) The files should now be accessible at `https://assets.publishing.service.gov.uk/government/uploads/uploaded/hmrc/{file}`, it may take a few minutes for the larger files to be scanned by the virus checker. 
7) Download copies of all the files using these  links, and re-check them against the SHA256 files.
7) If the files all pass the SHA check, then provide the links to the Content Designer for HMRC to conduct their Pre-live testing.
## Live release

Once HMRC have tested the files, they will confirm they are ready to go live.

The only additional step for us at this point is uploading the non-test version of the `realtimepayetools-` `.xml` file and providing the link to the Content Designer. They will then update the pages which need to use the new links.

Deleting the test version of this file is not required.

## Known Issues

### Existing file not updating

If the update involves changing the content of an existing file (such as the metadata file in the case of minor or patch versions), sometimes that file may fail to actually update the contents despite the rake task not raising an error.

1) Open a Bash session with one of the Asset Manager pods
```bash
kubectl exec -it deploy/asset-manager --bash
```
2) Get the file's asset ID
```bash
bundle exec rake assets:get_id_by_legacy_url_path[/government/uploads/uploaded/hmrc/{filename}]
```
3) Load a Rails Console session in Asset Manager
4) Check that the Asset is not stuck with a state of "unscanned"
```Ruby
file = Asset.find("{id}")
file.state
```
5) If it is, manually re-save the Asset to trigger a fresh virus scan
```ruby
file.save!
```


### ClamAV File Size

In the past we have had some issues with ClamAV failing to process these files because the contents of the individual zips are too big to unpack and scan. The size of these files has grown steadily year by year.

This has been solved previously by raising the [MaxFileSize](https://github.com/alphagov/govuk-helm-charts/pull/4147) and [StreamMaxLength](https://github.com/alphagov/govuk-helm-charts/pull/4148) on Asset Manager's ClamAV configmap. If this needs doing again, a conversation will be required with the Content APIs team.