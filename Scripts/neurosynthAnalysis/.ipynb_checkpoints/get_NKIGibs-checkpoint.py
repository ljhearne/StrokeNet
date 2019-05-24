'''
Code that uses boto to download the Gibs preprocessed NKI data from amazon s3.
For a better example see http://fcon_1000.projects.nitrc.org/indi/enhanced/download_rockland_raw_bids.py

Luke J Hearne 2019
'''

# Import packages
import pandas
import boto3
import botocore
import os

# For anonymous access to the bucket.
from botocore import UNSIGNED
from botocore.client import Config
from botocore.handlers import disable_signing

def download_data(s3_bucket_name='fcp-indi',s3_prefix='data/Projects/RocklandSample/Outputs/gibbs/structural/',out_dir='/Users/luke/Desktop/'):
    
    '''
    See http://fcon_1000.projects.nitrc.org/indi/enhanced/download_rockland_raw_bids.py for a more comprehensive coding example
    Inputs:
    s3_bucket_name: e.g.,'fcp-indi',
    s3_prefix:      e.g., 'data/Projects/RocklandSample/Outputs/gibbs/structural/',
    out_dir:        e.g., '/Users/luke/Desktop/'
    '''
    
    # Fetch bucket
    s3 = boto3.resource('s3')
    s3.meta.client.meta.events.register('choose-signer.s3.*', disable_signing)
    s3_bucket = s3.Bucket(s3_bucket_name)
    #
    s3_keys = s3_bucket.objects.filter(Prefix=s3_prefix)
    s3_keylist = [key.key for key in s3_keys]
    s3_client = boto3.client('s3',config=Config(signature_version=UNSIGNED))
    
    # And download the items. All the items are the Total number of rows in s3_keylist
    total_num_files = len(s3_keylist)
    files_downloaded = len(s3_keylist)

    for path_idx, s3_path in enumerate(s3_keylist):
        print (s3_path)
        #Remove the string /data/Projects/RocklandSample/RawDataBIDS for each path in list
        rel_path = s3_path.replace(s3_prefix, '')
        # Remove the FIRST slash from string
        rel_path = rel_path.lstrip('/')
        # Create a location path  for the folder and file path
        download_file = os.path.join(out_dir, rel_path)
        download_dir = os.path.dirname(download_file)

        print ('Downloading to: %s' % download_file)
        # Download the files in the just created folder
        with open(download_file, 'wb') as f:
            s3_client.download_fileobj(s3_bucket_name, s3_path, f)
        print ('%.3f%% percent complete' % \
              (100*(float(path_idx+1)/total_num_files)))

# repeat for structure and function data
out_dir ='/Users/luke/Documents/Projects/StrokeNet/Data/NKI_func/'
#download_data(s3_bucket_name='fcp-indi',s3_prefix='data/Projects/RocklandSample/Outputs/gibbs/structural/',out_dir=out_dir)
download_data(s3_bucket_name='fcp-indi',s3_prefix='data/Projects/RocklandSample/Outputs/gibbs/functional/',out_dir=out_dir)
print('*****ALL DOWNLOADS FINISHED*****')