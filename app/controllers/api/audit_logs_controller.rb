module Api
  class AuditLogsController < ApplicationController
    def index
      require_role!(:admin)

      audit_logs = current_organization.audit_logs
                                       .order(created_at: :desc, id: :desc)
                                       .yield_self { |scope| filter_by_event(scope) }
                                       .yield_self { |scope| filter_by_target_type(scope) }
                                       .yield_self { |scope| filter_by_created_since(scope) }
                                       .limit(limit)
                                       .offset(offset)

      render json: {
        data: audit_logs.map { |audit_log| AuditLogSerializer.render(audit_log) },
        meta: { limit:, offset:, returned: audit_logs.size }
      }
    end

    private

    def filter_by_event(scope)
      params[:event].present? ? scope.where(action: params[:event]) : scope
    end

    def filter_by_target_type(scope)
      params[:target_type].present? ? scope.where(target_type: params[:target_type]) : scope
    end

    def filter_by_created_since(scope)
      return scope if params[:created_since].blank?

      scope.where(created_at: Time.iso8601(params[:created_since]))
    rescue ArgumentError
      raise ActionController::ParameterMissing, "created_since must be an ISO8601 timestamp"
    end

    def limit
      [[params.fetch(:limit, 25).to_i, 100].min, 1].max
    end

    def offset
      [params.fetch(:offset, 0).to_i, 0].max
    end
  end
end
