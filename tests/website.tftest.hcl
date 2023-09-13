# Configure the provider default tags 
provider "aws" {
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

# Call the setup module to create a random bucket prefix
run "setup" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the bucket
run "create_bucket" {
  command = apply

  variables {
    bucket_name = "${run.setup.bucket_prefix}-aws-s3-website-test"
  }

  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.s3_bucket.bucket == "${run.setup.bucket_prefix}-aws-s3-website-test"
    error_message = "Invalid bucket name. Wanted ${run.setup.bucket_prefix}-aws-s3-website-test, got ${aws_s3_bucket.s3_bucket.bucket}"
  }
}

# Check the integrity of the files uploaded
run "file_etags" {
  command = plan

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./www/index.html")
    error_message = "Invalid eTag for index.html. Wanted ${filemd5("./www/index.html")}, got ${aws_s3_object.index.etag}"
  }

  # Check error.html hash matches
  assert {
    condition     = aws_s3_object.error.etag == filemd5("./www/error.html")
    error_message = "Invalid eTag for error.html. Wanted ${filemd5("./www/error.html")}, got ${aws_s3_object.error.etag}"
  }
}

# Check that the website is running and responding to requests
run "website_is_rinning" {
  command = plan

  module {
    source = "./tests/final"
  }

  variables {
    endpoint = run.file_etags.website_endpoint
  }

  # index.html responds with 200
  assert {
    condition     = data.http.index.status_code == 200
    error_message = "Index responded with HTTP status ${data.http.index.status_code}"
  }

  # index.html has the expectec content
  assert {
    condition     = strcontains(data.http.index.response_body, "Terramino")
    error_message = "Index page does not contain 'Terramino'"
  }
}