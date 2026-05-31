import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:handori/features/organization/data/dto/organization_group_response.dart';
import 'package:handori/features/organization/data/dto/organization_node_raw_response.dart';

part 'organization_api.g.dart';

@RestApi()
abstract class OrganizationApi {
  factory OrganizationApi(Dio dio, {String? baseUrl}) = _OrganizationApi;

  @GET('/static-info/organization/tree')
  Future<OrganizationGroupResponse> getTree();

  @GET('/static-info/organization/search/{name}')
  Future<List<OrganizationNodeRawResponse>> searchByName(
    @Path('name') String name,
  );

  @GET('/static-info/organization/{orgPath}')
  Future<OrganizationNodeRawResponse> getByPath(
    @Path('orgPath') String orgPath,
  );

  @GET('/static-info/organization/{orgPath}/children')
  Future<List<OrganizationNodeRawResponse>> getChildren(
    @Path('orgPath') String orgPath,
  );
}
