defmodule ExAws.SES.ParserTest do
  use ExUnit.Case, async: true

  alias ExAws.SES.Parsers

  def to_success(doc) do
    {:ok, %{body: doc}}
  end

  def to_error(doc) do
    {:error, {:http_error, 403, %{body: doc}}}
  end

  test "#parse a verify_email_identity response" do
    rsp = """
      <VerifyEmailIdentityResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
      <VerifyEmailIdentityResult/>
        <ResponseMetadata>
          <RequestId>d8eb8250-be9b-11e6-b7f7-d570946af758</RequestId>
        </ResponseMetadata>
      </VerifyEmailIdentityResponse>
    """
    |> to_success


    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :verify_email_identity)
    assert parsed_doc == %{request_id: "d8eb8250-be9b-11e6-b7f7-d570946af758"}
  end

  test "#parse identity_verification_attributes" do
    rsp = """
      <GetIdentityVerificationAttributesResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
        <GetIdentityVerificationAttributesResult>
          <VerificationAttributes>
            <entry>
              <key>example.com</key>
              <value>
                <VerificationToken>pwCRTZ8zHIJu+vePnXEa4DJmDyGhjSS8V3TkzzL2jI8=</VerificationToken>
                <VerificationStatus>Pending</VerificationStatus>
              </value>
            </entry>
            <entry>
              <key>user@example.com</key>
              <value>
                <VerificationStatus>Pending</VerificationStatus>
              </value>
            </entry>
          </VerificationAttributes>
        </GetIdentityVerificationAttributesResult>
        <ResponseMetadata>
          <RequestId>f5e3ef21-bec1-11e6-b618-27019a58dab9</RequestId>
        </ResponseMetadata>
      </GetIdentityVerificationAttributesResponse>
    """
    |> to_success

    verification_attributes = %{
      "example.com" => %{
        verification_token: "pwCRTZ8zHIJu+vePnXEa4DJmDyGhjSS8V3TkzzL2jI8=",
        verification_status: "Pending"
      },
      "user@example.com" => %{
        verification_status: "Pending"
      }
    }


    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :get_identity_verification_attributes)
    assert parsed_doc[:verification_attributes] == verification_attributes
  end

  test "#parse configuration_sets" do
    rsp = """
      <ListConfigurationSetsResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <ListConfigurationSetsResult>
          <ConfigurationSets>
            <member>
              <Name>test</Name>
            </member>
          </ConfigurationSets>
          <NextToken>QUFBQUF</NextToken>
        </ListConfigurationSetsResult>
        <ResponseMetadata>
          <RequestId>c177d6ce-c1b0-11e6-9770-29713cf492ad</RequestId>
        </ResponseMetadata>
      </ListConfigurationSetsResponse>
    """
    |> to_success

    configuration_sets = %{
      members: ["test"],
      next_token: "QUFBQUF"
    }

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :list_configuration_sets)
    assert parsed_doc[:configuration_sets] == configuration_sets
  end

  test "#parse send_email" do
    rsp = """
    <SendEmailResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
      <SendEmailResult>
        <MessageId>0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000</MessageId>
      </SendEmailResult>
      <ResponseMetadata>
        <RequestId>8194094b-c58a-11e6-b49d-838795cc7d3f</RequestId>
      </ResponseMetadata>
    </SendEmailResponse>
    """
    |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :send_email)
    assert parsed_doc == %{
      request_id: "8194094b-c58a-11e6-b49d-838795cc7d3f",
      message_id: "0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000"
    }
  end

  test "#parse error" do
    rsp = """
      <ErrorResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/\">
        <Error>
          <Type>Sender</Type>
          <Code>MalformedInput</Code>
          <Message>Top level element may not be treated as a list</Message>
        </Error>
        <RequestId>3ac0a9e8-bebd-11e6-9ec4-e5c47e708fa8</RequestId>
      </ErrorResponse>
    """
    |> to_error


    {:error, {:http_error, 403, err}} = Parsers.parse(rsp, :get_identity_verification_attributes)

    assert "Sender" == err[:type]
    assert "MalformedInput" == err[:code]
    assert "Top level element may not be treated as a list" == err[:message]
    assert "3ac0a9e8-bebd-11e6-9ec4-e5c47e708fa8" == err[:request_id]
  end
end
