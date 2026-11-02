# Render bootstrap for TrailAtlas

Application source, CI and public race data are maintained at https://tangled.org/lalalurch.tngl.sh/trailatlas-swift .

Render's dashboard rejects the Tangled repository URL as a direct build source. This branch therefore contains only the Docker build entry point and this note. The build clones the public Tangled repository and verifies the exact application commit `eaddc37eefb69e95710b76479f499569fd5ef401` before compiling the original Swift application and copying its resources.

Production URL: https://trailatlas-swift.onrender.com/ . No private Git key is supplied to Render. The free plan, existing service and stable session key are retained. Source deployments remain explicit; public data refreshes are independent of this bootstrap.
